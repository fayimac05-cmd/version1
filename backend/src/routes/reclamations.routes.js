const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const { envoyerNotificationAuto } = require('../controllers/notifications.controller');

const ADMIN_ROLES = ['admin', 'direction'];

const baseSelect = `
  SELECT r.*,
         u.nom, u.prenoms, u.matricule,
         COALESCE(r.module_nom, m.nom) AS module_nom,
         f.nom AS filiere_etudiant
  FROM reclamations r
  JOIN users u ON u.id = r.etudiant_id
  LEFT JOIN etudiants e ON e.user_id = u.id
  LEFT JOIN filieres f ON f.id = e.filiere_id
  LEFT JOIN modules m ON m.id::text = r.module_id
`;

// GET /api/reclamations - Liste des reclamations
router.get('/', authMiddleware, async (req, res) => {
  try {
    const isAdmin = ADMIN_ROLES.includes(req.user.role);
    let query, params;

    if (isAdmin) {
      query = `${baseSelect} ORDER BY r.created_at DESC`;
      params = [];
    } else {
      query = `${baseSelect} WHERE r.etudiant_id = $1 ORDER BY r.created_at DESC`;
      params = [req.user.id];
    }

    const result = await pool.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[reclamations] GET /', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/reclamations - Creer une reclamation
router.post('/', authMiddleware, async (req, res) => {
  try {
    const {
      module_id,
      module_nom,
      type,
      type_eval,
      justification,
      parties_contestees,
      note_actuelle,
      semestre,
      annee,
      filiere,
      photo_url,
      modules_contestes,
    } = req.body;

    if (!type?.trim() || !justification?.trim()) {
      return res.status(400).json({ success: false, message: 'Type et justification requis.' });
    }

    const result = await pool.query(
      `INSERT INTO reclamations (
         etudiant_id, module_id, module_nom, type, type_eval,
         justification, parties_contestees, note_actuelle,
         semestre, annee, filiere, photo_url, modules_contestes, statut
       )
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'en_attente')
       RETURNING *`,
      [
        req.user.id,
        module_id ? String(module_id) : null,
        module_nom?.trim() || null,
        type.trim(),
        type_eval?.trim() || null,
        justification.trim(),
        parties_contestees?.trim() || null,
        note_actuelle != null ? Number(note_actuelle) : null,
        semestre?.trim() || null,
        annee?.trim() || null,
        filiere?.trim() || null,
        photo_url?.trim() || null,
        modules_contestes ? JSON.stringify(modules_contestes) : null,
      ]
    );

    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[reclamations] POST /', err);
    res.status(500).json({ success: false, message: 'Erreur creation reclamation.' });
  }
});

// GET /api/reclamations/:id - Detaille d'une reclamation
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(
      `${baseSelect} WHERE r.id = $1`,
      [req.params.id]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Reclamation non trouvee.' });
    }
    const rec = result.rows[0];
    if (
      rec.etudiant_id !== req.user.id &&
      !ADMIN_ROLES.includes(req.user.role) &&
      req.user.role !== 'professeur'
    ) {
      return res.status(403).json({ success: false, message: 'Acces refuse.' });
    }
    res.json({ success: true, data: rec });
  } catch (err) {
    console.error('[reclamations] GET /:id', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// PATCH /api/reclamations/:id - Mettre a jour (admin / professeur)
router.patch('/:id', authMiddleware, requireRole('admin', 'direction', 'professeur'), async (req, res) => {
  try {
    const { statut, reponse, prof_transfere } = req.body;
    if (!statut?.trim()) {
      return res.status(400).json({ success: false, message: 'Statut requis.' });
    }

    const sets = ['statut = $1'];
    const params = [statut.trim()];
    let idx = 2;

    if (reponse !== undefined) {
      sets.push(`reponse = $${idx++}`);
      params.push(reponse?.trim() || null);
    }
    if (prof_transfere !== undefined) {
      sets.push(`prof_transfere = $${idx++}`);
      params.push(prof_transfere?.trim() || null);
    }
    if (['resolu', 'rejete'].includes(statut.trim())) {
      sets.push('date_traitement = CURRENT_TIMESTAMP');
    }

    params.push(req.params.id);
    const result = await pool.query(
      `UPDATE reclamations SET ${sets.join(', ')} WHERE id = $${idx} RETURNING *`,
      params
    );

    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Reclamation non trouvee.' });
    }

    const rec = result.rows[0];

    if (['resolu', 'rejete', 'en_cours'].includes(statut.trim())) {
      const titre =
        statut.trim() === 'resolu'
          ? 'Réclamation acceptée'
          : statut.trim() === 'rejete'
            ? 'Réclamation rejetée'
            : 'Réclamation en cours de traitement';
      const corps =
        reponse?.trim() ||
        (statut.trim() === 'en_cours'
          ? `Votre réclamation a été transférée${prof_transfere ? ' à ' + prof_transfere : ''}.`
          : 'Consultez vos réclamations pour plus de détails.');
      await envoyerNotificationAuto(rec.etudiant_id, titre, corps);
    }

    res.json({ success: true, data: rec });
  } catch (err) {
    console.error('[reclamations] PATCH /:id', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

module.exports = router;
