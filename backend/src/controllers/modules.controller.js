const db = require('../../config/db');

// Récupérer tous les modules (optionnellement filtrés par filière)
exports.getAllModules = async (req, res) => {
  const { filiere_id } = req.query;
  try {
    let query = 'SELECT * FROM modules';
    let params = [];
    if (filiere_id) {
      query += ' WHERE filiere_id = $1';
      params.push(filiere_id);
    }
    query += ' ORDER BY nom ASC';
    const result = await db.query(query, params);
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Créer un module
exports.createModule = async (req, res) => {
  const { nom, coefficient, volume_horaire, filiere_id } = req.body;
  try {
    const result = await db.query(
      'INSERT INTO modules (nom, coefficient, volume_horaire, filiere_id) VALUES ($1, $2, $3, $4) RETURNING *',
      [nom, coefficient, volume_horaire, filiere_id]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Mettre à jour un module
exports.updateModule = async (req, res) => {
  const { id } = req.params;
  const { nom, coefficient, volume_horaire, filiere_id } = req.body;
  try {
    const result = await db.query(
      'UPDATE modules SET nom = $1, coefficient = $2, volume_horaire = $3, filiere_id = COALESCE($4, filiere_id) WHERE id = $5 RETURNING *',
      [nom, coefficient, volume_horaire, filiere_id, id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Module non trouvé' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Supprimer un module
exports.deleteModule = async (req, res) => {
  const { id } = req.params;
  try {
    const result = await db.query('DELETE FROM modules WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Module non trouvé' });
    }
    res.json({ message: 'Module supprimé avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Assigner un professeur à un module
exports.assignProfessor = async (req, res) => {
  const { module_id, professeur_id } = req.body;
  try {
    // Vérifier si la liaison existe déjà
    const check = await db.query(
      'SELECT * FROM module_professeur WHERE module_id = $1 AND professeur_id = $2',
      [module_id, professeur_id]
    );
    if (check.rows.length > 0) {
      return res.status(400).json({ error: 'Ce professeur est déjà assigné à ce module' });
    }
    
    await db.query(
      'INSERT INTO module_professeur (module_id, professeur_id) VALUES ($1, $2)',
      [module_id, professeur_id]
    );
    res.json({ message: 'Professeur assigné avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
