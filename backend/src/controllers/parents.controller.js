const pool = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { envoyerNotificationAuto } = require('./notifications.controller');

const genToken = (user) => jwt.sign(
  { id: user.id, role: user.role },
  process.env.JWT_SECRET,
  { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
);

// ── Helper interne : créer ou réutiliser un parent par téléphone ─────────────
// Utilisé par createParent (admin) ET par etudiants.controller.js::creerOuLierParent
// (inscription étudiant) — même logique, deux points d'entrée différents.
const trouverOuCreerParent = async (client, { nom, prenoms, tel, email }) => {
  const telClean = tel.trim();
  const existant = await client.query('SELECT id FROM parents WHERE tel = $1', [telClean]);
  if (existant.rows.length > 0) {
    return { parentId: existant.rows[0].id, cree: false };
  }
  const nouveau = await client.query(
    `INSERT INTO parents (nom, prenoms, tel, email, statut)
     VALUES ($1, $2, $3, $4, 'actif') RETURNING id`,
    [nom.trim().toUpperCase(), prenoms?.trim() || null, telClean, email?.trim() || null]
  );
  return { parentId: nouveau.rows[0].id, cree: true };
};

// ── Vérifie qu'un etudiantId appartient bien au parent connecté ─────────────
// Renvoie true/false. Un admin/direction passe toujours (pas de restriction).
const etudiantAppartientAuParent = async (parentUserId, etudiantId) => {
  const r = await pool.query(
    `SELECT 1 FROM parents p
     JOIN parent_etudiants pe ON pe.parent_id = p.id
     WHERE p.user_id::text = $1 AND pe.etudiant_id = $2`,
    [parentUserId.toString(), etudiantId]
  );
  return r.rows.length > 0;
};

// ── GET /api/parents (admin) ──────────────────────────────────────────────────
// Liste les parents déjà liés (avec leurs enfants agrégés) + les étudiants
// dont le champ tuteur est renseigné sur `etudiants` mais qui n'ont PAS encore
// de compte parent lié — c'est cette seconde liste que l'écran admin dédié
// utilise pour proposer un rattachement a posteriori.
const getParents = async (req, res) => {
  try {
    const parentsResult = await pool.query(`
      SELECT p.id, p.nom, p.prenoms, p.tel, p.email, (p.user_id IS NOT NULL) AS compte_actif,
             json_agg(
               json_build_object(
                 'etudiantId', e.id,
                 'matricule', e.matricule,
                 'nom', e.nom,
                 'prenoms', e.prenoms,
                 'filiere', e.filiere_nom,
                 'niveau', e.niveau,
                 'relation', pe.relation
               ) ORDER BY e.nom
             ) AS enfants
      FROM parents p
      JOIN parent_etudiants pe ON pe.parent_id = p.id
      JOIN etudiants e ON e.id = pe.etudiant_id
      GROUP BY p.id, p.nom, p.prenoms, p.tel, p.email, p.user_id
      ORDER BY p.nom
    `);

    const sansLienResult = await pool.query(`
      SELECT e.id AS etudiant_id, e.matricule, e.nom, e.prenoms,
             e.nom_parent, e.tel_parent, e.email_parent
      FROM etudiants e
      LEFT JOIN parent_etudiants pe ON pe.etudiant_id = e.id
      WHERE pe.etudiant_id IS NULL
        AND e.tel_parent IS NOT NULL AND e.tel_parent != ''
      ORDER BY e.nom
    `);

    res.json({
      success: true,
      parents: parentsResult.rows,
      enfantsSansTuteurLie: sansLienResult.rows,
    });
  } catch (err) {
    console.error('[parents.controller] GET /', err.message);
    res.status(500).json({ success: false, message: err.message });
  }
};

// ── POST /api/parents (admin) ─────────────────────────────────────────────────
// Lie (ou crée puis lie) un tuteur à UN étudiant, désigné par son matricule.
// body: { nom, prenoms, telephone, email, matriculeEnfant, remplacerExistant? }
// - Si l'étudiant a déjà un tuteur principal, renvoie 409 sauf si
//   remplacerExistant=true (l'admin choisit alors explicitement de remplacer).
// - L'admin ne définit JAMAIS de mot de passe : le compte reste "en attente"
//   (user_id = null) jusqu'à ce que le parent se connecte lui-même et le
//   définisse via /api/parents/finaliser (flux self-service uniquement).
const createParent = async (req, res) => {
  const client = await pool.connect();
  try {
    const { nom, prenoms, telephone, email, matriculeEnfant, relation, remplacerExistant } = req.body;

    if (!nom?.trim() || !telephone?.trim() || !matriculeEnfant?.trim()) {
      return res.status(400).json({
        success: false,
        message: 'Nom, téléphone et matricule de l\'enfant sont obligatoires.',
      });
    }

    const etuRes = await client.query(
      'SELECT id, nom, prenoms FROM etudiants WHERE UPPER(matricule) = UPPER($1)',
      [matriculeEnfant.trim()]
    );
    if (etuRes.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: `Étudiant introuvable avec le matricule: ${matriculeEnfant}`,
      });
    }
    const etudiant = etuRes.rows[0];

    // Vérifier si un tuteur principal existe déjà pour cet étudiant
    const lienExistant = await client.query(
      `SELECT pe.parent_id, p.nom, p.prenoms
       FROM parent_etudiants pe JOIN parents p ON p.id = pe.parent_id
       WHERE pe.etudiant_id = $1`,
      [etudiant.id]
    );
    if (lienExistant.rows.length > 0 && !remplacerExistant) {
      const t = lienExistant.rows[0];
      return res.status(409).json({
        success: false,
        conflict: true,
        message: `${etudiant.prenoms} ${etudiant.nom} a déjà un tuteur principal (${t.prenoms || ''} ${t.nom}).`,
      });
    }
    if (lienExistant.rows.length > 0 && remplacerExistant) {
      await client.query('DELETE FROM parent_etudiants WHERE etudiant_id = $1', [etudiant.id]);
    }

    // Créer ou réutiliser le parent (par téléphone)
    const { parentId, cree } = await trouverOuCreerParent(client, {
      nom, prenoms, tel: telephone, email,
    });

    // Lier
    await client.query(
      `INSERT INTO parent_etudiants (parent_id, etudiant_id, relation) VALUES ($1, $2, $3)
       ON CONFLICT (etudiant_id) DO NOTHING`,
      [parentId, etudiant.id, relation?.trim() || 'Tuteur']
    );

    // Garder les champs d'affichage sur etudiants synchronisés (utilisés par
    // ex. dans la fiche étudiant admin, section "Contact d'urgence")
    await client.query(
      `UPDATE etudiants SET nom_parent = $1, tel_parent = $2, email_parent = $3 WHERE id = $4`,
      [
        `${nom.trim().toUpperCase()} ${prenoms?.trim() || ''}`.trim(),
        telephone.trim(),
        email?.trim() || null,
        etudiant.id,
      ]
    );

    res.json({
      success: true,
      message: cree
        ? 'Parent créé et lié avec succès. Il devra se connecter lui-même pour activer son compte.'
        : 'Parent existant lié à cet enfant.',
      parentId,
    });
  } catch (err) {
    console.error('[parents.controller] POST / ERREUR:', err.message);
    res.status(500).json({ success: false, message: `Erreur: ${err.message}` });
  } finally {
    client.release();
  }
};

// ── DELETE /api/parents/lien/:etudiantId (admin) ──────────────────────────────
// Retire le lien tuteur↔enfant (ne supprime pas le compte parent, qui peut
// rester lié à d'autres enfants — cas fratrie).
const supprimerLien = async (req, res) => {
  try {
    const { etudiantId } = req.params;
    const r = await pool.query('DELETE FROM parent_etudiants WHERE etudiant_id = $1 RETURNING parent_id', [etudiantId]);
    if (r.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Aucun lien trouvé pour cet étudiant.' });
    }
    res.json({ success: true, message: 'Lien retiré.' });
  } catch (err) {
    console.error('[parents.controller] DELETE /lien/:id', err.message);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── POST /api/parents/finaliser (public) ──────────────────────────────────────
// Première connexion : crée la ligne `users` pour un parent trouvé dans
// `parents` sans user_id (voir auth.controller.js::login, Fallback parents).
const finaliserPremiereConnexion = async (req, res) => {
  const { parentId, password, email, telephone } = req.body;
  try {
    if (!parentId) return res.status(400).json({ message: 'parentId requis.' });
    if (!password || password.trim().length < 4) {
      return res.status(400).json({ message: 'Le mot de passe doit contenir au moins 4 caractères.' });
    }

    const pRes = await pool.query('SELECT * FROM parents WHERE id = $1', [parentId]);
    const parent = pRes.rows[0];
    if (!parent) return res.status(404).json({ message: 'Parent introuvable.' });
    if (parent.user_id) return res.status(409).json({ message: 'Ce compte a déjà été activé.' });

    const hashed = await bcrypt.hash(password, 10);
    const userRes = await pool.query(
      `INSERT INTO users (nom, prenoms, email, tel, role, statut, mot_de_passe)
       VALUES ($1, $2, $3, $4, 'parent', 'actif', $5) RETURNING id`,
      [parent.nom, parent.prenoms, email?.trim() || parent.email || null, telephone?.trim() || parent.tel, hashed]
    );
    const userId = userRes.rows[0].id;

    await pool.query(
      'UPDATE parents SET user_id = $1, email = COALESCE($2, email), tel = COALESCE($3, tel) WHERE id = $4',
      [userId, email || null, telephone || null, parentId]
    );

    envoyerNotificationAuto(
      userId,
      'Bienvenue sur ScolarHub',
      'Votre compte parent a été activé avec succès.',
      'premiere_connexion',
      null
    ).catch(() => {});

    const token = genToken({ id: userId, role: 'parent' });
    res.status(200).json({
      success: true,
      message: 'Compte parent activé avec succès.',
      token,
      user: {
        id: userId,
        parentId,
        nom: parent.nom,
        prenoms: parent.prenoms,
        email: email || parent.email || '',
        telephone: telephone || parent.tel,
        role: 'parent',
      },
    });
  } catch (err) {
    console.error('[finaliserPremiereConnexion]', err);
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Email déjà utilisé.' });
    }
    res.status(500).json({ message: err.message || 'Erreur lors de l\'activation du compte.' });
  }
};

// ── GET /api/parents/mes-enfants (parent connecté) ────────────────────────────
// Remplace l'ancien /mon-enfant (singulier) : un parent peut avoir plusieurs
// enfants (fratrie). Sert la page d'accueil parent (cartes moyenne+présence
// +badges) et le sélecteur d'enfant persistant du shell.
const getMesEnfants = async (req, res) => {
  try {
    const parentUserId = req.user.id.toString();

    // Initialise la date de "dernière consultation" à maintenant pour tout
    // enfant/type qui n'en a pas encore — évite un badge géant sur de
    // l'historique ancien à la toute première ouverture.
    await pool.query(
      `INSERT INTO parent_consultations (parent_id, etudiant_id, type, derniere_consultation)
       SELECT p.id, e.id, t, now()
       FROM parents p
       JOIN parent_etudiants pe ON pe.parent_id = p.id
       JOIN etudiants e ON e.id = pe.etudiant_id,
       unnest(ARRAY['notes','bulletins']) AS t
       WHERE p.user_id::text = $1
       ON CONFLICT (parent_id, etudiant_id, type) DO NOTHING`,
      [parentUserId]
    );

    const result = await pool.query(
      `SELECT e.id AS etudiant_id, e.matricule, e.nom, e.prenoms,
              COALESCE(e.filiere_nom, f.nom) AS filiere_nom,
              e.niveau, e.filiere_id,
              (SELECT ROUND(AVG(valeur)::numeric, 2) FROM vue_notes_etudiants WHERE etudiant_id = e.id) AS moyenne,
              (SELECT ROUND(100.0 * COUNT(*) FILTER (WHERE presence_statut = 'present') / NULLIF(COUNT(*), 0), 1)
                 FROM vue_presences_etudiants WHERE etudiant_id = e.id) AS taux_presence,
              (SELECT COUNT(*) FROM vue_notes_etudiants vn
                 WHERE vn.etudiant_id = e.id AND vn.date_session > COALESCE(pc_notes.derniere_consultation, now())) AS notes_non_lues,
              (SELECT COUNT(*) FROM bulletins b
                 WHERE b.etudiant_id = e.id AND b.publie = true
                   AND b.date_publication > COALESCE(pc_bulletins.derniere_consultation, now())) AS bulletins_non_lus
       FROM parents p
       JOIN parent_etudiants pe ON pe.parent_id = p.id
       JOIN etudiants e ON e.id = pe.etudiant_id
       LEFT JOIN filieres f ON f.id = e.filiere_id
       LEFT JOIN parent_consultations pc_notes
         ON pc_notes.parent_id = p.id AND pc_notes.etudiant_id = e.id AND pc_notes.type = 'notes'
       LEFT JOIN parent_consultations pc_bulletins
         ON pc_bulletins.parent_id = p.id AND pc_bulletins.etudiant_id = e.id AND pc_bulletins.type = 'bulletins'
       WHERE p.user_id::text = $1
       ORDER BY e.nom, e.prenoms`,
      [parentUserId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Aucun enfant rattaché trouvé.' });
    }
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[parents] GET /mes-enfants', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── POST /api/parents/consultation (parent connecté) ──────────────────────────
// Marque un onglet (notes/bulletins) comme consulté pour un enfant donné —
// remet le badge "nouveau" à zéro pour ce couple enfant+type à partir de
// maintenant. À appeler quand le parent ouvre l'onglet correspondant.
const marquerConsulte = async (req, res) => {
  try {
    const { etudiantId, type } = req.body;
    if (!etudiantId || !['notes', 'bulletins'].includes(type)) {
      return res.status(400).json({ success: false, message: 'etudiantId et type (notes|bulletins) requis.' });
    }
    const isAdmin = ['admin', 'direction'].includes(req.user.role);
    if (!isAdmin && !(await etudiantAppartientAuParent(req.user.id, etudiantId))) {
      return res.status(403).json({ success: false, message: 'Accès refusé à cet étudiant.' });
    }
    await pool.query(
      `INSERT INTO parent_consultations (parent_id, etudiant_id, type, derniere_consultation)
       SELECT p.id, $2, $3, now() FROM parents p WHERE p.user_id::text = $1
       ON CONFLICT (parent_id, etudiant_id, type) DO UPDATE SET derniere_consultation = now()`,
      [req.user.id.toString(), etudiantId, type]
    );
    res.json({ success: true });
  } catch (err) {
    console.error('[parents] POST /consultation', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── GET /api/parents/enfant/:etudiantId/bulletins (parent, scopé) ─────────────
const getBulletinsEnfant = async (req, res) => {
  try {
    const { etudiantId } = req.params;
    const isAdmin = ['admin', 'direction'].includes(req.user.role);
    if (!isAdmin && !(await etudiantAppartientAuParent(req.user.id, etudiantId))) {
      return res.status(403).json({ success: false, message: 'Accès refusé à cet étudiant.' });
    }
    const result = await pool.query(
      `SELECT id, semestre, annee_academique, moyenne_generale, statut, date_publication
       FROM bulletins
       WHERE etudiant_id = $1 AND publie = true
       ORDER BY annee_academique DESC, semestre DESC`,
      [etudiantId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[parents] GET /enfant/:id/bulletins', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── GET /api/parents/enfant/:etudiantId (admin) ───────────────────────────────
// Champs d'affichage tuteur stockés sur `etudiants` (édition administrative,
// distincte du compte parent réel lié via parent_etudiants).
const getInfoTuteur = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT nom_parent, tel_parent, email_parent FROM etudiants WHERE id = $1`,
      [req.params.etudiantId]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Étudiant non trouvé.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[parents] GET /enfant/:id', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── PUT /api/parents/enfant/:etudiantId (admin) ───────────────────────────────
const modifierInfoTuteur = async (req, res) => {
  try {
    const { nom_parent, tel_parent, email_parent } = req.body;
    const result = await pool.query(
      `UPDATE etudiants SET nom_parent = COALESCE($1, nom_parent),
       tel_parent = COALESCE($2, tel_parent), email_parent = COALESCE($3, email_parent)
       WHERE id = $4 RETURNING nom_parent, tel_parent, email_parent`,
      [nom_parent, tel_parent, email_parent, req.params.etudiantId]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Étudiant non trouvé.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[parents] PUT /enfant/:id', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── GET /api/parents/enfant/:etudiantId/notes (parent, scopé) ─────────────────
const getNotesEnfant = async (req, res) => {
  try {
    const { etudiantId } = req.params;
    const isAdmin = ['admin', 'direction'].includes(req.user.role);
    if (!isAdmin && !(await etudiantAppartientAuParent(req.user.id, etudiantId))) {
      return res.status(403).json({ success: false, message: 'Accès refusé à cet étudiant.' });
    }
    const result = await pool.query(
      `SELECT * FROM vue_notes_etudiants WHERE etudiant_id = $1 ORDER BY date_session DESC`,
      [etudiantId]
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[parents] GET /enfant/:id/notes', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── GET /api/parents/enfant/:etudiantId/presences (parent, scopé) ─────────────
// Historique détaillé — regroupement par module fait côté Flutter à partir de
// cette liste chronologique brute (chaque ligne porte déjà le module).
const getPresencesEnfant = async (req, res) => {
  try {
    const { etudiantId } = req.params;
    const isAdmin = ['admin', 'direction'].includes(req.user.role);
    if (!isAdmin && !(await etudiantAppartientAuParent(req.user.id, etudiantId))) {
      return res.status(403).json({ success: false, message: 'Accès refusé à cet étudiant.' });
    }
    const result = await pool.query(
      `SELECT * FROM vue_presences_etudiants WHERE etudiant_id = $1 ORDER BY date_appel DESC`,
      [etudiantId]
    );

    const total = result.rows.length;
    const presentes = result.rows.filter(r => r.presence_statut === 'present').length;
    const absentes = result.rows.filter(r => r.presence_statut === 'absent').length;
    const retards = result.rows.filter(r => r.presence_statut === 'retard').length;

    res.json({
      success: true,
      data: result.rows,
      stats: { total, presentes, absentes, retards },
    });
  } catch (err) {
    console.error('[parents] GET /enfant/:id/presences', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── GET /api/parents/mon-profil (parent connecté) ─────────────────────────────
// Infos du tuteur lui-même (nom, prénom, tel, email) — distinct de
// getMesEnfants qui liste les enfants rattachés.
const getMonProfil = async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT p.id, p.nom, p.prenoms, p.tel, p.email
       FROM parents p WHERE p.user_id::text = $1`,
      [req.user.id.toString()]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Profil parent introuvable.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[parents] GET /mon-profil', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

module.exports = {
  getParents,
  createParent,
  supprimerLien,
  finaliserPremiereConnexion,
  getMesEnfants,
  getMonProfil,
  marquerConsulte,
  getBulletinsEnfant,
  getInfoTuteur,
  modifierInfoTuteur,
  getNotesEnfant,
  getPresencesEnfant,
  etudiantAppartientAuParent,
};