const db = require('../config/db');

exports.uploadCours = async (req, res) => {
  try {
    const { titre, description, filiere_id, filiere_nom, niveau, module_id } = req.body;
    const professeur_id = req.user.id;
    const fichier_url = req.uploadedFileUrl;

    if (!titre || !filiere_id || !module_id || !fichier_url) {
      return res.status(400).json({ success: false, message: 'Paramètres manquants' });
    }

    const result = await db.query(`
      INSERT INTO supports_cours 
      (titre, description, filiere_id, filiere_nom, niveau, module_id, professeur_id, fichier_url) 
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8) 
      RETURNING *
    `, [titre, description, filiere_id, filiere_nom || '', niveau || 'Tous', module_id, professeur_id, fichier_url]);

    res.status(201).json({ success: true, message: 'Cours uploadé avec succès', data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getCours = async (req, res) => {
  try {
    const professeur_id = req.user.id;
    const result = await db.query(`
      SELECT sc.*, m.nom as module_nom 
      FROM supports_cours sc
      JOIN modules m ON sc.module_id = m.id
      WHERE sc.professeur_id = $1
      ORDER BY sc.date_creation DESC
    `, [professeur_id]);

    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
