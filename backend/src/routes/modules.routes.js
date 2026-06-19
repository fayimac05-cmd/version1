const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');

// GET /api/modules - Liste de tous les modules
router.get('/', async (req, res) => {
  try {
    const { filiere_id } = req.query;
    let query = `
      SELECT m.id, m.nom, m.coefficient, m.volume_horaire, m.filiere_id, m.filiere_nom,
             f.nom AS filiere
      FROM modules m
      LEFT JOIN filieres f ON f.id = m.filiere_id
    `;
    const params = [];
    if (filiere_id) {
      query += ' WHERE m.filiere_id = $1';
      params.push(filiere_id);
    }
    query += ' ORDER BY m.nom';
    const result = await pool.query(query, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[modules] GET /', err);
    res.status(500).json({ success: false, message: 'Erreur chargement modules.' });
  }
});

// GET /api/modules/:id - Detaille d'un module
router.get('/:id', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT m.*, f.nom AS filiere
       FROM modules m LEFT JOIN filieres f ON f.id = m.filiere_id
       WHERE m.id = $1`,
      [req.params.id]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Module non trouve.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[modules] GET /:id', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/modules - Creer un module (admin)
router.post('/', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { nom, coefficient, volume_horaire, filiere_id, filiere_nom } = req.body;
    if (!nom?.trim()) {
      return res.status(400).json({ success: false, message: 'Nom du module requis.' });
    }
    const result = await pool.query(
      `INSERT INTO modules (nom, coefficient, volume_horaire, filiere_id, filiere_nom)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [nom.trim(), coefficient || 1, volume_horaire || null, filiere_id || null, filiere_nom || null]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[modules] POST /', err);
    res.status(500).json({ success: false, message: 'Erreur creation module.' });
  }
});

// PUT /api/modules/:id - Modifier un module (admin)
router.put('/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { nom, coefficient, volume_horaire, filiere_id, filiere_nom } = req.body;
    const result = await pool.query(
      `UPDATE modules SET nom = COALESCE($1, nom), coefficient = COALESCE($2, coefficient),
       volume_horaire = COALESCE($3, volume_horaire), filiere_id = COALESCE($4, filiere_id),
       filiere_nom = COALESCE($5, filiere_nom)
       WHERE id = $6 RETURNING *`,
      [nom, coefficient, volume_horaire, filiere_id, filiere_nom, req.params.id]
    );
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Module non trouve.' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[modules] PUT /:id', err);
    res.status(500).json({ success: false, message: 'Erreur modification module.' });
  }
});

// DELETE /api/modules/:id - Supprimer un module (admin)
router.delete('/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM modules WHERE id = $1 RETURNING id', [req.params.id]);
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Module non trouve.' });
    }
    res.json({ success: true, message: 'Module supprime.' });
  } catch (err) {
    console.error('[modules] DELETE /:id', err);
    res.status(500).json({ success: false, message: 'Erreur suppression module.' });
  }
});

module.exports = router;
