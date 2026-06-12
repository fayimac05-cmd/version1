const db = require('../config/db');

exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await db.query(`
      SELECT u.id as user_id, u.nom, u.prenoms, u.email, u.tel, u.matricule, u.role, u.filiere_nom as departement, p.specialite 
      FROM users u 
      LEFT JOIN professeurs p ON u.id = p.user_id 
      WHERE u.id = $1
    `, [userId]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Professeur non trouvé' });
    }
    
    res.json({ success: true, data: result.rows[0] });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const { nom, prenoms, tel, email, specialite, departement } = req.body;
    
    await db.query(`
      UPDATE users SET nom = $1, prenoms = $2, tel = $3, email = $4, filiere_nom = $5 
      WHERE id = $6
    `, [nom, prenoms, tel, email, departement, userId]);
    
    // Create or update professeur details
    const pResult = await db.query(`SELECT id FROM professeurs WHERE user_id = $1`, [userId]);
    if (pResult.rows.length > 0) {
      await db.query(`UPDATE professeurs SET specialite = $1 WHERE user_id = $2`, [specialite, userId]);
    } else {
      await db.query(`INSERT INTO professeurs (user_id, specialite) VALUES ($1, $2)`, [userId, specialite]);
    }
    
    res.json({ success: true, message: 'Profil mis à jour avec succès' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getClasses = async (req, res) => {
  try {
    // In our system, "Classes" can be approximated by filieres and niveaux
    // A professor teaches certain modules which belong to certain filieres
    const userId = req.user.id;
    
    const result = await db.query(`
      SELECT DISTINCT f.id, f.nom, f.description, 'Tous' as niveau
      FROM filieres f
      JOIN modules m ON f.id = m.filiere_id
      JOIN module_professeur mp ON m.id = mp.module_id
      JOIN professeurs p ON mp.professeur_id = p.id
      WHERE p.user_id = $1
    `, [userId]);
    
    // If empty (no assigned modules), fetch all filieres to avoid empty state during dev
    if (result.rows.length === 0) {
      const allFilieres = await db.query(`SELECT id, nom, description, 'Tous' as niveau FROM filieres`);
      return res.json({ success: true, data: allFilieres.rows });
    }
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getModules = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await db.query(`
      SELECT m.id, m.nom, m.coefficient, m.volume_horaire, m.filiere_id, m.filiere_nom 
      FROM modules m 
      JOIN module_professeur mp ON m.id = mp.module_id 
      JOIN professeurs p ON mp.professeur_id = p.id
      WHERE p.user_id = $1
    `, [userId]);
    
    // If empty, return all modules for now (or empty list if strict)
    if (result.rows.length === 0) {
       const allMods = await db.query(`SELECT m.id, m.nom, m.coefficient, m.volume_horaire, m.filiere_id, m.filiere_nom FROM modules m`);
       return res.json({ success: true, data: allMods.rows });
    }
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getStudentsByFiliere = async (req, res) => {
  try {
    const { filiere_id } = req.params;
    const result = await db.query(`
      SELECT id, nom, prenoms, matricule, email, tel, niveau
      FROM etudiants
      WHERE filiere_id = $1
      ORDER BY nom ASC
    `, [filiere_id]);
    
    res.json({ success: true, data: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
