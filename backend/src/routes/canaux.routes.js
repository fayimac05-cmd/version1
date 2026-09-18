const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const { getOrCreateCanalAdminFiliereNiveau } = require('../utils/canauxProfDelegue');

// GET /api/canaux/mes-coordinations — pour un délégué/adjoint connecté :
// liste ses sous-fils "Professeurs & Délégués" (un par professeur qui lui
// enseigne, dans sa propre filière/niveau) — auto-peuplé via canal_membres
// au moment où chaque sous-fil a été créé (voir getOrCreateCanalProfDelegue).
router.get('/mes-coordinations', authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT c.id AS canal_id, c.niveau, c.filiere_id, f.nom AS filiere_nom,
              u.nom AS prof_nom, u.prenoms AS prof_prenoms
       FROM canal_membres cm
       JOIN canaux c ON c.id = cm.canal_id AND c.type = 'prof_delegue_niveau'
       JOIN filieres f ON f.id = c.filiere_id
       JOIN users u ON u.id = c.professeur_id
       WHERE cm.user_id = $1
       ORDER BY u.nom, u.prenoms`,
      [req.user.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) {
    console.error('[canaux] mes-coordinations', err);
    res.status(500).json({ success: false, message: 'Erreur chargement des canaux de coordination.' });
  }
});

// GET /api/canaux/mon-admin-filiere — pour un étudiant connecté : résout
// (et crée si besoin) le canal "Admin Filière" de SA propre filière/niveau.
router.get('/mon-admin-filiere', authMiddleware, async (req, res) => {
  try {
    const { rows } = await pool.query(
      `SELECT e.filiere_id, f.nom AS filiere_nom, e.niveau
       FROM etudiants e JOIN filieres f ON f.id = e.filiere_id
       WHERE e.user_id = $1`,
      [req.user.id]
    );
    if (!rows[0]) {
      return res.status(404).json({ success: false, message: 'Profil étudiant introuvable.' });
    }
    const { filiere_id, filiere_nom, niveau } = rows[0];
    const canalId = await getOrCreateCanalAdminFiliereNiveau(filiere_id, niveau);
    res.json({ success: true, data: { canal_id: canalId, filiere_nom, niveau } });
  } catch (err) {
    console.error('[canaux] mon-admin-filiere', err);
    res.status(500).json({ success: false, message: 'Erreur chargement du canal Admin Filière.' });
  }
});

// GET /api/canaux/admin-filieres — hiérarchie Admin Filière : pour chaque
// filière réellement enregistrée en base, la liste de ses niveaux (ceux qui
// comptent au moins un étudiant), chacun rattaché à son canal dédié
// (créé automatiquement au premier accès si besoin).
router.get('/admin-filieres', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const combos = await pool.query(
      `SELECT DISTINCT f.id AS filiere_id, f.nom AS filiere_nom, e.niveau
       FROM etudiants e
       JOIN filieres f ON f.id = e.filiere_id
       WHERE e.niveau IS NOT NULL AND e.niveau != ''
       ORDER BY f.nom, e.niveau`
    );

    const parFiliere = {};
    for (const c of combos.rows) {
      const canalId = await getOrCreateCanalAdminFiliereNiveau(c.filiere_id, c.niveau);
      if (!parFiliere[c.filiere_id]) {
        parFiliere[c.filiere_id] = { filiere_id: c.filiere_id, filiere_nom: c.filiere_nom, niveaux: [] };
      }
      parFiliere[c.filiere_id].niveaux.push({ niveau: c.niveau, canal_id: canalId });
    }

    res.json({ success: true, data: Object.values(parFiliere) });
  } catch (err) {
    console.error('[canaux] admin-filieres', err);
    res.status(500).json({ success: false, message: 'Erreur chargement des canaux Admin Filière.' });
  }
});

router.get('/professeur-filieres', authMiddleware, async (req, res) => {
  const role = String(req.user.role || '').toLowerCase().trim();
  if (!['admin', 'professeur', 'prof', 'enseignant', 'teacher'].includes(role)) {
    return res.status(403).json({ success: false, message: 'Accès réservé aux professeurs.' });
  }
  try {
    const filieres = await pool.query('SELECT id, nom, description FROM filieres ORDER BY nom');
    const result = [];
    for (const filiere of filieres.rows) {
      const type = `prof_delegues:${filiere.id}`;
      const existing = await pool.query('SELECT id FROM canaux WHERE type = $1 LIMIT 1', [type]);
      let canalId = existing.rows[0]?.id;
      if (!canalId) {
        const nextId = await pool.query("SELECT COALESCE(MAX(id), 0) + 1 AS id FROM canaux");
        canalId = nextId.rows[0].id;
        const { data, error } = await require('../config/supabase')
          .from('canaux')
          .insert({
            id: canalId,
            nom: `Professeurs & Délégués · ${filiere.nom}`,
            description: `Coordination pédagogique de ${filiere.nom}`,
            type,
          })
          .select('id')
          .single();
        if (error) throw error;
        canalId = data.id;
      }
      const membres = await pool.query(
        `SELECT DISTINCT u.id, u.nom, u.prenoms, u.role,
                 CASE WHEN LOWER(u.role) IN ('professeur', 'prof', 'enseignant') THEN 'Professeur'
                   WHEN LOWER(u.etudiant_role) = 'delegue' OR LOWER(u.role) = 'delegue' THEN 'Chef de filière'
                     ELSE 'Sous-chef de filière' END AS fonction
         FROM users u
         LEFT JOIN etudiants e ON e.user_id = u.id
         LEFT JOIN professeurs p ON p.user_id = u.id
         LEFT JOIN module_professeur mp ON mp.professeur_id = p.id
         LEFT JOIN modules m ON m.id = mp.module_id
         WHERE (LOWER(u.role) IN ('professeur', 'prof', 'enseignant')
                AND (m.filiere_id = $1 OR NOT EXISTS (
                  SELECT 1 FROM module_professeur mp2
                  JOIN professeurs p2 ON p2.id = mp2.professeur_id
                  WHERE p2.user_id = u.id
                )))
            OR (e.filiere_id = $1 AND (LOWER(u.etudiant_role) IN ('delegue', 'delegue_adjoint')
              OR LOWER(u.role) IN ('delegue', 'delegue_adjoint')))
         ORDER BY fonction, u.nom`,
        [filiere.id],
      );
      result.push({ ...filiere, id: canalId, filiere_id: filiere.id, type, membres: membres.rows });
    }
    res.json({ success: true, data: result });
  } catch (err) {
    console.error('[canaux] professeur-filieres', err);
    res.status(500).json({ success: false, message: 'Erreur chargement des canaux par filière.' });
  }
});

// GET /api/canaux - Liste de tous les canaux
router.get('/', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT c.id, c.nom, c.description, c.type, c.created_at,
             (SELECT COUNT(*) FROM canal_membres cm WHERE cm.canal_id = c.id) AS nb_membres
      FROM canaux c
      ORDER BY c.nom
    `);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[canaux] GET /', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// POST /api/canaux - Creer un canal (admin)
router.post('/', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { nom, description, type } = req.body;
    if (!nom?.trim()) {
      return res.status(400).json({ success: false, message: 'Nom du canal requis.' });
    }
    const result = await pool.query(
      `INSERT INTO canaux (nom, description, type) VALUES ($1, $2, $3) RETURNING *`,
      [nom.trim(), description || null, type || 'general']
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    console.error('[canaux] POST /', err);
    res.status(500).json({ success: false, message: 'Erreur creation canal.' });
  }
});

// POST /api/canaux/:id/membres - Ajouter un membre a un canal
router.post('/:id/membres', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const { user_id, role } = req.body;
    if (!user_id) {
      return res.status(400).json({ success: false, message: 'user_id requis.' });
    }
    await pool.query(
      `INSERT INTO canal_membres (canal_id, user_id, role) VALUES ($1, $2, $3)
       ON CONFLICT (canal_id, user_id) DO UPDATE SET role = $3`,
      [req.params.id, user_id, role || 'membre']
    );
    res.status(201).json({ success: true, message: 'Membre ajoute au canal.' });
  } catch (err) {
    console.error('[canaux] POST /:id/membres', err);
    res.status(500).json({ success: false, message: 'Erreur ajout membre.' });
  }
});

// GET /api/canaux/:id/membres - Liste des membres d'un canal
router.get('/:id/membres', authMiddleware, async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT u.id, u.nom, u.prenoms, u.matricule, u.role, cm.role AS canal_role
      FROM canal_membres cm
      JOIN users u ON u.id = cm.user_id
      WHERE cm.canal_id = $1
      ORDER BY u.nom
    `, [req.params.id]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    console.error('[canaux] GET /:id/membres', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
});

// DELETE /api/canaux/:id - Supprimer un canal (admin)
router.delete('/:id', authMiddleware, requireRole('admin'), async (req, res) => {
  try {
    const result = await pool.query('DELETE FROM canaux WHERE id = $1 RETURNING id', [req.params.id]);
    if (!result.rows[0]) {
      return res.status(404).json({ success: false, message: 'Canal non trouve.' });
    }
    res.json({ success: true, message: 'Canal supprime.' });
  } catch (err) {
    console.error('[canaux] DELETE /:id', err);
    res.status(500).json({ success: false, message: 'Erreur suppression canal.' });
  }
});

module.exports = router;