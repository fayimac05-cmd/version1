const db = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

// Connexion Étudiant (via matricule)
exports.loginEtudiant = async (req, res) => {
  const { matricule, password } = req.body;
  try {
    const result = await db.query('SELECT * FROM etudiants WHERE matricule = $1', [matricule.toUpperCase()]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Matricule non reconnu' });
    }

    const student = result.rows[0];

    // Si c'est la première fois, il n'a pas encore de mot de passe
    if (student.premierefois && !student.password) {
      return res.json({ 
        message: 'Première connexion détectée', 
        premiereFois: true,
        student: { id: student.id, nom: student.nom, prenoms: student.prenoms }
      });
    }

    const isMatch = await bcrypt.compare(password, student.password);
    if (!isMatch) {
      return res.status(401).json({ error: 'Mot de passe incorrect' });
    }

    const token = jwt.sign(
      { id: student.id, role: 'etudiant' },
      process.env.JWT_SECRET || 'scolarhub_secret_key',
      { expiresIn: '30d' }
    );

    res.json({
      token,
      user: {
        id: student.id,
        matricule: student.matricule,
        nom: student.nom,
        prenoms: student.prenoms,
        role: 'etudiant',
        filiere_id: student.filiere_id
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// Finaliser l'inscription (Première fois)
exports.finaliserInscription = async (req, res) => {
  const { id, email, password } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await db.query(
      'UPDATE etudiants SET email = $1, password = $2, premierefois = FALSE WHERE id = $3 RETURNING *',
      [email, hashedPassword, id]
    );
    
    if (result.rows.length === 0) return res.status(404).json({ error: 'Étudiant non trouvé' });
    
    res.json({ message: 'Compte créé avec succès', student: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
