const pool = require('../config/db');
const { envoyerNotificationAuto } = require('./notifications.controller');

// ════════════════════════════════════════════════════════════════════════════
// BULLETINS — deux étapes distinctes, conçues avec Ib :
//
// PARTIE 1 — "Prévision de moyenne" (getPrevisionMoyenne) : tableau en
// lecture seule, un étudiant par ligne, un GROUPE de colonnes par module
// (Note 1, Note 2, ..., Moyenne du module — simple moyenne des notes de ce
// module, SANS coefficient). Sert juste à visualiser avant calcul final.
//
// PARTIE 2 — "Publication des bulletins" (getPreparationBulletin +
// publierBulletins) : reprend les mêmes moyennes de module, les pondère
// CETTE FOIS par le coefficient de chaque module (une seule fois par
// module, peu importe son nombre de devoirs) pour obtenir la moyenne
// générale. L'admin peut corriger cette moyenne générale à la main avant
// de choisir Validé/Ajourné/Invalidé et de publier.
//
// ⚠️ BUG CORRIGÉ — l'ancienne requête pondérait chaque NOTE individuelle
// par le coefficient de son module (SUM(n.valeur * m.coefficient) /
// SUM(m.coefficient) sur la table `notes` jointe directement), ce qui
// faisait peser un module avec 3 devoirs trois fois plus qu'un module à
// coefficient identique mais avec 1 seul devoir. Désormais : moyenne de
// chaque module d'abord (poids égal peu importe le nombre de devoirs),
// PUIS pondération par coefficient — un seul poids par module.
// ════════════════════════════════════════════════════════════════════════════

// Brique de calcul partagée entre Prévision et Bulletins — pour chaque
// étudiant de la filière+niveau, la liste de ses modules du semestre avec
// notes (dans l'ordre chronologique des sessions) + moyenne simple du
// module (sans coefficient).
const _calculerMoyennesModules = async (filiere_id, niveau, semestre, annee_academique) => {
    const modulesRes = await pool.query(`
        SELECT DISTINCT m.id, m.nom, m.coefficient
        FROM modules m
        JOIN sessions_notes sn ON sn.module_id = m.id
        WHERE m.filiere_id = $1 AND sn.semestre = $2 AND sn.annee_academique = $3 AND sn.statut = 'validee'
        ORDER BY m.nom
    `, [filiere_id, semestre, annee_academique]);
    const modules = modulesRes.rows;

    const etudiantsRes = await pool.query(
        `SELECT id, matricule, nom, prenoms FROM etudiants WHERE filiere_id = $1 AND niveau = $2 ORDER BY nom, prenoms`,
        [filiere_id, niveau]
    );

    if (modules.length === 0) {
        return { modules: [], etudiants: etudiantsRes.rows.map(e => ({ ...e, modules: [] })) };
    }

    const moduleIds = modules.map(m => m.id);
    const sessionsRes = await pool.query(`
        SELECT id, module_id FROM sessions_notes
        WHERE module_id = ANY($1::int[]) AND semestre = $2 AND annee_academique = $3 AND statut = 'validee'
        ORDER BY id ASC
    `, [moduleIds, semestre, annee_academique]);
    const sessionsParModule = {};
    for (const s of sessionsRes.rows) {
        sessionsParModule[s.module_id] ??= [];
        sessionsParModule[s.module_id].push(s.id);
    }
    const allSessionIds = sessionsRes.rows.map(s => s.id);

    let notesParEtudiantSession = {};
    if (allSessionIds.length > 0) {
        const notesRes = await pool.query(
            `SELECT etudiant_id, session_id, valeur FROM notes WHERE session_id = ANY($1::uuid[])`,
            [allSessionIds]
        );
        for (const row of notesRes.rows) {
            notesParEtudiantSession[row.etudiant_id] ??= {};
            notesParEtudiantSession[row.etudiant_id][row.session_id] = parseFloat(row.valeur);
        }
    }

    const etudiants = etudiantsRes.rows.map(e => {
        const modulesEtudiant = modules.map(m => {
            const sessionIds = sessionsParModule[m.id] || [];
            const notes = sessionIds.map(sid => notesParEtudiantSession[e.id]?.[sid] ?? null);
            const notesValides = notes.filter(n => n !== null);
            const moyenneModule = notesValides.length > 0
                ? Math.round((notesValides.reduce((s, n) => s + n, 0) / notesValides.length) * 100) / 100
                : null;
            return {
                module_id: m.id,
                module_nom: m.nom,
                coefficient: m.coefficient,
                notes,
                moyenne_module: moyenneModule,
            };
        });
        return { etudiant_id: e.id, matricule: e.matricule, nom: e.nom, prenoms: e.prenoms, modules: modulesEtudiant };
    });

    return { modules, etudiants };
};

const _moyenneGenerale = (modules) => {
    const avecNote = modules.filter(m => m.moyenne_module !== null);
    const sommeCoef = avecNote.reduce((s, m) => s + Number(m.coefficient || 0), 0);
    if (sommeCoef === 0) return null;
    const sommePonderee = avecNote.reduce((s, m) => s + m.moyenne_module * Number(m.coefficient || 0), 0);
    return Math.round((sommePonderee / sommeCoef) * 100) / 100;
};

// ── PARTIE 1 ──────────────────────────────────────────────────────────────
// GET /api/bulletins/prevision?filiere_id=&niveau=&semestre=&annee_academique=
const getPrevisionMoyenne = async (req, res) => {
    try {
        const { filiere_id, niveau, semestre, annee_academique } = req.query;
        if (!filiere_id || !niveau || !semestre || !annee_academique) {
            return res.status(400).json({ success: false, message: 'filiere_id, niveau, semestre et annee_academique sont requis.' });
        }
        const { modules, etudiants } = await _calculerMoyennesModules(filiere_id, niveau, semestre, annee_academique);
        res.json({ success: true, data: { modules, etudiants } });
    } catch (error) {
        console.error('[getPrevisionMoyenne]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du calcul de la prévision.' });
    }
};

// ── PARTIE 2 ──────────────────────────────────────────────────────────────
// GET /api/bulletins/preparation?filiere_id=&niveau=&semestre=&annee_academique=
const getPreparationBulletin = async (req, res) => {
    try {
        const { filiere_id, niveau, semestre, annee_academique } = req.query;
        if (!filiere_id || !niveau || !semestre || !annee_academique) {
            return res.status(400).json({ success: false, message: 'filiere_id, niveau, semestre et annee_academique sont requis.' });
        }

        const { etudiants: etudiantsModules } = await _calculerMoyennesModules(filiere_id, niveau, semestre, annee_academique);

        const bulletinsRes = await pool.query(
            `SELECT etudiant_id, id, statut, publie, date_publication FROM bulletins WHERE semestre = $1 AND annee_academique = $2`,
            [semestre, annee_academique]
        );
        const bulletinsParEtudiant = {};
        for (const b of bulletinsRes.rows) bulletinsParEtudiant[b.etudiant_id] = b;

        const filiereRes = await pool.query('SELECT nom FROM filieres WHERE id = $1', [filiere_id]);
        const filiereNom = filiereRes.rows[0]?.nom || '';

        const data = etudiantsModules.map(e => {
            const b = bulletinsParEtudiant[e.etudiant_id];
            const moyenneCalculee = _moyenneGenerale(e.modules);
            return {
                etudiant_id: e.etudiant_id,
                matricule: e.matricule,
                nom: e.nom,
                prenoms: e.prenoms,
                filiere_nom: filiereNom,
                niveau,
                moyenne_calculee: moyenneCalculee,
                nb_notes: e.modules.filter(m => m.moyenne_module !== null).length, // = nb modules pris en compte
                bulletin_id: b?.id || null,
                bulletin_statut: b?.statut || null,
                bulletin_publie: b?.publie === true,
                date_publication: b?.date_publication || null,
                detail_modules: e.modules,
            };
        });

        res.json({ success: true, data });
    } catch (error) {
        console.error('[getPreparationBulletin]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du calcul des moyennes.' });
    }
};

// POST /api/bulletins/publier (admin)
// Body : { filiere_id, niveau, semestre, annee_academique,
//          resultats: [{ etudiant_id, statut, moyenne? }] }
// `moyenne` optionnel : si l'admin l'a corrigée à la main dans l'écran,
// cette valeur est utilisée telle quelle au lieu de la moyenne recalculée
// automatiquement — c'est le point "ces moyennes sont modifiables".
const publierBulletins = async (req, res) => {
    try {
        const { filiere_id, niveau, semestre, annee_academique, resultats } = req.body;
        const admin_id = req.user.id;

        if (!filiere_id || !niveau || !semestre || !annee_academique) {
            return res.status(400).json({
                success: false,
                message: 'filiere_id, niveau, semestre et annee_academique sont requis.',
            });
        }
        if (!Array.isArray(resultats) || resultats.length === 0) {
            return res.status(400).json({ success: false, message: 'Aucun résultat à publier.' });
        }
        const statutsValides = ['valide', 'ajourne', 'invalide'];
        for (const r of resultats) {
            if (!r.etudiant_id || !statutsValides.includes(r.statut)) {
                return res.status(400).json({
                    success: false,
                    message: `Statut invalide pour l'étudiant ${r.etudiant_id}. Attendu : valide, ajourne ou invalide.`,
                });
            }
        }

        const { etudiants: etudiantsModules } = await _calculerMoyennesModules(filiere_id, niveau, semestre, annee_academique);
        const modulesParEtudiant = {};
        for (const e of etudiantsModules) modulesParEtudiant[e.etudiant_id] = e.modules;

        const publies = [];
        const echecs = [];

        const idsEtudiants = resultats.map(r => r.etudiant_id);
        const usersMap = {};
        if (idsEtudiants.length > 0) {
            const uRes = await pool.query(
                `SELECT id, user_id FROM etudiants WHERE id = ANY($1::int[])`,
                [idsEtudiants]
            );
            for (const row of uRes.rows) usersMap[row.id] = row.user_id;
        }

        for (const r of resultats) {
            try {
                const modules = modulesParEtudiant[r.etudiant_id] || [];
                const moyenneCalculee = _moyenneGenerale(modules);
                const moyenne = (r.moyenne !== undefined && r.moyenne !== null)
                    ? Number(r.moyenne)
                    : moyenneCalculee;

                const upsert = await pool.query(`
                    INSERT INTO bulletins (
                        etudiant_id, filiere_id, niveau, semestre, annee_academique,
                        moyenne_generale, statut, publie, admin_id, date_publication, detail_modules
                    )
                    VALUES ($1, $2, $3, $4, $5, $6, $7, true, $8, now(), $9)
                    ON CONFLICT (etudiant_id, semestre, annee_academique)
                    DO UPDATE SET
                        moyenne_generale = EXCLUDED.moyenne_generale,
                        statut = EXCLUDED.statut,
                        publie = true,
                        admin_id = EXCLUDED.admin_id,
                        date_publication = now(),
                        detail_modules = EXCLUDED.detail_modules
                    RETURNING id, etudiant_id, moyenne_generale, statut
                `, [r.etudiant_id, filiere_id, niveau, semestre, annee_academique, moyenne, r.statut, admin_id, JSON.stringify(modules)]);

                if (upsert.rows[0]) {
                    publies.push(upsert.rows[0]);
                    const destUserId = usersMap[r.etudiant_id];
                    if (destUserId) {
                        envoyerNotificationAuto(
                            destUserId,
                            'Bulletin publié',
                            `Votre bulletin du ${semestre} (${annee_academique}) est disponible. Moyenne générale : ${moyenne ?? '--'}/20.`,
                            'bulletin',
                            { semestre, annee_academique }
                        ).catch(() => {});
                    }
                } else {
                    echecs.push({ etudiant_id: r.etudiant_id, raison: 'Aucune ligne retournée.' });
                }
            } catch (err) {
                console.error('[publierBulletins] echec etudiant', r.etudiant_id, err.message);
                echecs.push({ etudiant_id: r.etudiant_id, raison: err.message });
            }
        }

        res.json({
            success: publies.length > 0,
            message: echecs.length === 0
                ? `${publies.length} bulletin(s) publié(s).`
                : `${publies.length} bulletin(s) publié(s), ${echecs.length} échec(s).`,
            data: publies,
            echecs: echecs.length > 0 ? echecs : undefined,
        });
    } catch (error) {
        console.error('[publierBulletins]', error);
        res.status(500).json({ success: false, message: 'Erreur lors de la publication des bulletins.' });
    }
};

// GET /api/bulletins/mon-bulletin (étudiant connecté)
const getMonBulletin = async (req, res) => {
    try {
        const userId = req.user.id;

        const etudiantResult = await pool.query(
            `SELECT id, nom, prenoms, filiere_nom, niveau FROM etudiants WHERE user_id = $1`,
            [userId]
        );
        const etudiant = etudiantResult.rows[0];
        if (!etudiant) {
            return res.status(404).json({ success: false, message: 'Profil étudiant introuvable.' });
        }

        const result = await pool.query(`
            SELECT id, semestre, annee_academique, moyenne_generale, statut, date_publication, detail_modules
            FROM bulletins
            WHERE etudiant_id = $1 AND publie = true
            ORDER BY annee_academique DESC, semestre DESC
        `, [etudiant.id]);

        res.json({
            success: true,
            data: result.rows,
            etudiant: {
                nom: etudiant.nom,
                prenoms: etudiant.prenoms,
                filiere_nom: etudiant.filiere_nom,
                niveau: etudiant.niveau,
            },
        });
    } catch (error) {
        console.error('[getMonBulletin]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du chargement du bulletin.' });
    }
};

// POST /api/bulletins/prevision/envoyer (admin) — rend la prévision visible
// aux étudiants du groupe et les notifie. Ne fige rien : la prévision reste
// calculée en direct à chaque consultation, seule la "permission de voir"
// est enregistrée.
const envoyerPrevision = async (req, res) => {
    try {
        const { filiere_id, niveau, semestre, annee_academique } = req.body;
        if (!filiere_id || !niveau || !semestre || !annee_academique) {
            return res.status(400).json({ success: false, message: 'filiere_id, niveau, semestre et annee_academique sont requis.' });
        }
        await pool.query(
            `INSERT INTO previsions_envoyees (filiere_id, niveau, semestre, annee_academique, envoye_par)
             VALUES ($1, $2, $3, $4, $5)
             ON CONFLICT (filiere_id, niveau, semestre, annee_academique)
             DO UPDATE SET envoye_par = EXCLUDED.envoye_par, created_at = now()`,
            [filiere_id, niveau, semestre, annee_academique, req.user.id]
        );

        (async () => {
            try {
                const etusRes = await pool.query(
                    `SELECT u.id FROM users u
                     JOIN etudiants e ON e.user_id = u.id
                     WHERE e.filiere_id = $1 AND e.niveau = $2
                       AND (u.role ILIKE '%etudiant%' OR u.role ILIKE '%delegue%' OR u.role ILIKE '%bde%')
                       AND COALESCE(u.statut, 'actif') NOT IN ('suspendu', 'renvoye')`,
                    [filiere_id, niveau]
                );
                for (const e of etusRes.rows) {
                    await envoyerNotificationAuto(
                        e.id,
                        'Prévision de moyenne disponible',
                        `Vos moyennes par module pour ${semestre} (${annee_academique}) sont consultables — ce n'est pas encore le bulletin final.`,
                        'prevision',
                        null
                    );
                }
            } catch (notifErr) {
                console.error('[envoyerPrevision] notification', notifErr.message);
            }
        })();

        res.json({ success: true, message: 'Prévision envoyée aux étudiants.' });
    } catch (error) {
        console.error('[envoyerPrevision]', error);
        res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi.' });
    }
};

// GET /api/bulletins/mes-previsions (étudiant) — une entrée par envoi reçu
// pour sa filière+niveau, recalculée en direct (jamais figée).
const getMesPrevisions = async (req, res) => {
    try {
        const userId = req.user.id;
        const etuRes = await pool.query('SELECT id, filiere_id, niveau FROM etudiants WHERE user_id = $1', [userId]);
        const etu = etuRes.rows[0];
        if (!etu || !etu.filiere_id) {
            return res.json({ success: true, data: [] });
        }

        const envoisRes = await pool.query(
            `SELECT semestre, annee_academique, created_at FROM previsions_envoyees
             WHERE filiere_id = $1 AND niveau = $2
             ORDER BY annee_academique DESC, semestre DESC`,
            [etu.filiere_id, etu.niveau]
        );

        const previsions = [];
        for (const envoi of envoisRes.rows) {
            const { etudiants } = await _calculerMoyennesModules(etu.filiere_id, etu.niveau, envoi.semestre, envoi.annee_academique);
            const moi = etudiants.find(e => e.etudiant_id === etu.id);
            previsions.push({
                semestre: envoi.semestre,
                annee_academique: envoi.annee_academique,
                date_envoi: envoi.created_at,
                modules: moi ? moi.modules : [],
            });
        }

        res.json({ success: true, data: previsions });
    } catch (error) {
        console.error('[getMesPrevisions]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du chargement.' });
    }
};

module.exports = {
    getPrevisionMoyenne,
    envoyerPrevision,
    getMesPrevisions,
    getPreparationBulletin,
    publierBulletins,
    getMonBulletin,
};