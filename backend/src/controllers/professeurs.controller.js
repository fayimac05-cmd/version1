const db = require('../../config/db');

// Récupérer tous les professeurs
exports.getAllProfesseurs = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM professeurs ORDER BY nom ASC');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Créer un professeur
exports.createProfesseur = async (req, res) => {
  const { nom, email, specialite } = req.body;
  try {
    const result = await db.query(
      'INSERT INTO professeurs (nom, email, specialite) VALUES ($1, $2, $3) RETURNING *',
      [nom, email, specialite]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Mettre à jour un professeur
exports.updateProfesseur = async (req, res) => {
  const { id } = req.params;
  const { nom, email, specialite } = req.body;
  try {
    const result = await db.query(
      'UPDATE professeurs SET nom = $1, email = $2, specialite = $3 WHERE id = $4 RETURNING *',
      [nom, email, specialite, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Professeur non trouvé' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Supprimer un professeur
exports.deleteProfesseur = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await db.query('DELETE FROM professeurs WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Professeur non trouvé' });
    }
    res.json({ message: 'Professeur supprimé avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Récupérer les modules d'un professeur
exports.getModulesByProfesseur = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await db.query(
      'SELECT m.* FROM modules m JOIN module_professeur mp ON m.id = mp.module_id WHERE mp.professeur_id = $1 ORDER BY m.nom ASC',
      [id]
    );
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Assigner ou retirer un module à un professeur (via PATCH)
exports.patchModuleAssignment = async (req, res) => {
  const { module_id, professeur_id, action } = req.body; // action: 'assign' ou 'remove'
  try {
    if (action === 'assign') {
      await db.query(
        'INSERT INTO module_professeur (module_id, professeur_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
        [module_id, professeur_id]
      );
    } else if (action === 'remove') {
      await db.query(
        'DELETE FROM module_professeur WHERE module_id = $1 AND professeur_id = $2',
        [module_id, professeur_id]
      );
    } else {
      return res.status(400).json({ error: "L'action doit être 'assign' ou 'remove'" });
    }
    res.json({ message: `Module ${action === 'assign' ? 'assigné' : 'retiré'} avec succès` });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
