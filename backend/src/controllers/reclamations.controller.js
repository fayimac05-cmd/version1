const pool = require('../config/db');
const { envoyerNotificationAuto } = require('./notifications.controller');

// ════════════════════════════════════════════════════════════════════════════
// RÉCLAMATIONS — contestation de note/moyenne/absence par un étudiant
// ⚠️ CORRIGÉ — reclamations.etudiant_id est de type uuid, il référence
// users.id (l'identité universelle), PAS etudiants.id (entier, utilisé
// ailleurs comme dans bulletins.controller.js). La jointure e.id =
// r.etudiant_id comparait un entier à un uuid → plantage SQL. Utilise
// maintenant directement req.user.id partout, plus simple et plus correct.
// ════════════════════════════════════════════════════════════════════════════

// POST /api/reclamations (étudiant)
const createReclamation = async (req, res) => {
    try {
        const userId = req.user.id;
        const {
            module_id, module_nom, type, type_eval, note_actuelle,
            semestre, annee, parties_contestees, justification, modules_contestes,
        } = req.body;

        if (!justification || !justification.trim()) {
            return res.status(400).json({ success: false, message: 'La justification est obligatoire.' });
        }
        const typesValides = ['note', 'moyenne', 'absence'];
        if (!type || !typesValides.includes(type)) {
            return res.status(400).json({ success: false, message: `Type invalide. Attendu : ${typesValides.join(', ')}.` });
        }

        const etuRes = await pool.query('SELECT filiere_nom FROM etudiants WHERE user_id = $1', [userId]);
        const filiereNom = etuRes.rows[0]?.filiere_nom || null;

        const insert = await pool.query(
            `INSERT INTO reclamations (
                etudiant_id, module_id, module_nom, type, type_eval, note_actuelle,
                semestre, annee, filiere, parties_contestees, justification, statut, modules_contestes
            ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,'en_attente',$12)
            RETURNING id`,
            [
                userId,
                module_id?.toString() || null,
                module_nom || null,
                type,
                type_eval || null,
                note_actuelle ?? null,
                semestre || null,
                annee || null,
                filiereNom,
                parties_contestees || null,
                justification.trim(),
                modules_contestes ? JSON.stringify(modules_contestes) : null,
            ]
        );

        res.status(201).json({ success: true, message: 'Réclamation envoyée à l\'administration.', id: insert.rows[0].id });
    } catch (error) {
        console.error('[createReclamation]', error);
        res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi de la réclamation.' });
    }
};

// GET /api/reclamations/mes-reclamations (étudiant connecté)
const getMesReclamations = async (req, res) => {
    try {
        const userId = req.user.id;
        const result = await pool.query(
            `SELECT * FROM reclamations WHERE etudiant_id = $1 ORDER BY created_at DESC`,
            [userId]
        );
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('[getMesReclamations]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du chargement.' });
    }
};

// GET /api/reclamations?statut=en_attente (admin)
const getAllReclamations = async (req, res) => {
    try {
        const { statut } = req.query;
        const params = [];
        let where = '';
        if (statut) {
            params.push(statut);
            where = `WHERE r.statut = $${params.length}`;
        }
        const result = await pool.query(
            `SELECT r.*, e.matricule, e.nom AS etudiant_nom, e.prenoms AS etudiant_prenoms
             FROM reclamations r
             LEFT JOIN etudiants e ON e.user_id = r.etudiant_id
             ${where}
             ORDER BY r.created_at DESC`,
            params
        );
        res.json({ success: true, data: result.rows });
    } catch (error) {
        console.error('[getAllReclamations]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du chargement des réclamations.' });
    }
};

// GET /api/reclamations/en-attente/count (admin) — badge du menu
const getNombreEnAttente = async (req, res) => {
    try {
        const result = await pool.query(`SELECT COUNT(*) FROM reclamations WHERE statut = 'en_attente'`);
        res.json({ success: true, count: parseInt(result.rows[0].count, 10) || 0 });
    } catch (error) {
        console.error('[getNombreEnAttente]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du comptage.' });
    }
};

// PATCH /api/reclamations/:id/transferer (admin) — body: { prof_transfere }
const transfererReclamation = async (req, res) => {
    try {
        const { id } = req.params;
        const { prof_transfere } = req.body;
        if (!prof_transfere || !prof_transfere.trim()) {
            return res.status(400).json({ success: false, message: 'Le professeur destinataire est requis.' });
        }
        const result = await pool.query(
            `UPDATE reclamations SET statut = 'en_cours', prof_transfere = $1 WHERE id = $2 RETURNING id`,
            [prof_transfere.trim(), id]
        );
        if (result.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Réclamation introuvable.' });
        }
        res.json({ success: true, message: 'Réclamation transférée.' });
    } catch (error) {
        console.error('[transfererReclamation]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du transfert.' });
    }
};

// PATCH /api/reclamations/:id/repondre (admin) — body: { reponse }
const repondreReclamation = async (req, res) => {
    try {
        const { id } = req.params;
        const { reponse } = req.body;
        if (!reponse || !reponse.trim()) {
            return res.status(400).json({ success: false, message: 'La réponse est requise.' });
        }
        const result = await pool.query(
            `UPDATE reclamations SET statut = 'resolu', reponse = $1, date_traitement = now()
             WHERE id = $2
             RETURNING id, etudiant_id, module_nom`,
            [reponse.trim(), id]
        );
        const rec = result.rows[0];
        if (!rec) {
            return res.status(404).json({ success: false, message: 'Réclamation introuvable.' });
        }

        // rec.etudiant_id EST déjà le user_id (uuid) — pas besoin de lookup.
        envoyerNotificationAuto(
            rec.etudiant_id,
            'Réclamation traitée',
            `Votre réclamation concernant ${rec.module_nom || 'un module'} a été résolue.`,
            'reclamation',
            null
        ).catch((e) => console.error('[repondreReclamation] notification', e.message));

        res.json({ success: true, message: 'Réponse envoyée.' });
    } catch (error) {
        console.error('[repondreReclamation]', error);
        res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi de la réponse.' });
    }
};

// PATCH /api/reclamations/:id/rejeter (admin) — body: { motif }
const rejeterReclamation = async (req, res) => {
    try {
        const { id } = req.params;
        const { motif } = req.body;
        const reponseFinale = motif && motif.trim() ? motif.trim() : 'Réclamation rejetée par l\'administration.';

        const result = await pool.query(
            `UPDATE reclamations SET statut = 'rejete', reponse = $1, date_traitement = now()
             WHERE id = $2
             RETURNING id, etudiant_id, module_nom`,
            [reponseFinale, id]
        );
        const rec = result.rows[0];
        if (!rec) {
            return res.status(404).json({ success: false, message: 'Réclamation introuvable.' });
        }

        envoyerNotificationAuto(
            rec.etudiant_id,
            'Réclamation traitée',
            `Votre réclamation concernant ${rec.module_nom || 'un module'} a été rejetée.`,
            'reclamation',
            null
        ).catch((e) => console.error('[rejeterReclamation] notification', e.message));

        res.json({ success: true, message: 'Réclamation rejetée.' });
    } catch (error) {
        console.error('[rejeterReclamation]', error);
        res.status(500).json({ success: false, message: 'Erreur lors du rejet.' });
    }
};

module.exports = {
    createReclamation,
    getMesReclamations,
    getAllReclamations,
    getNombreEnAttente,
    transfererReclamation,
    repondreReclamation,
    rejeterReclamation,
};