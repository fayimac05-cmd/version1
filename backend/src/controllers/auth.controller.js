const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const genToken = (user) => jwt.sign(
  { id: user.id, matricule: user.matricule, role: user.role, filiere_id: user.filiere_id, etablissement_id: user.etablissement_id },
  process.env.JWT_SECRET,
  { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
);

const login = async (req, res) => {
  try {
    const { matricule, nom, tel, motDePasse } = req.body;
    let user;

    if (matricule) {
      const r = await pool.query('SELECT * FROM users WHERE matricule = $1', [matricule.trim().toUpperCase()]);
      user = r.rows[0];
    } else if (nom && tel) {
      const r = await pool.query('SELECT * FROM users WHERE LOWER(nom) = LOWER($1) AND tel = $2', [nom.trim(), tel.trim()]);
      user = r.rows[0];
    } else {
      return res.status(400).json({ message: 'Identifiants manquants.' });
    }

    if (!user) return res.status(404).json({ message: 'Utilisateur introuvable.' });
    if (user.statut === 'suspendu') return res.status(403).json({ message: 'Compte suspendu.' });
    if (user.statut === 'renvoye')  return res.status(403).json({ message: 'Compte desactive.' });

    if (!user.mot_de_passe) {
      return res.status(200).json({ premierLogin: true, userId: user.id, message: 'Premiere connexion.' });
    }

    const isValid = await bcrypt.compare(motDePasse, user.mot_de_passe);
    if (!isValid) return res.status(401).json({ message: 'Mot de passe incorrect.' });

    return res.status(200).json({
      token: genToken(user),
      user: { id: user.id, nom: user.nom, prenoms: user.prenoms, matricule: user.matricule, role: user.role, filiere_id: user.filiere_id, etablissement_id: user.etablissement_id, domaine: user.domaine, statut: user.statut },
    });
  } catch (err) {
    console.error('Login error:', err);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

const setupPassword = async (req, res) => {
  try {
    const { userId, email, motDePasse } = req.body;
    if (!userId || !motDePasse) return res.status(400).json({ message: 'Donnees manquantes.' });
    const hashed = await bcrypt.hash(motDePasse, 10);
    await pool.query('UPDATE users SET mot_de_passe = $1, email = $2 WHERE id = $3', [hashed, email || null, userId]);
    const r = await pool.query('SELECT * FROM users WHERE id = $1', [userId]);
    const user = r.rows[0];
    return res.status(200).json({ token: genToken(user), user: { id: user.id, nom: user.nom, prenoms: user.prenoms, role: user.role } });
  } catch (err) {
    console.error('Setup error:', err);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

const me = async (req, res) => {
  try {
    const r = await pool.query(
      'SELECT id, nom, prenoms, matricule, email, tel, role, filiere_id, etablissement_id, domaine, statut FROM users WHERE id = $1',
      [req.user.id]
    );
    if (!r.rows[0]) return res.status(404).json({ message: 'Introuvable.' });
    return res.status(200).json(r.rows[0]);
  } catch (err) {
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

const changePassword = async (req, res) => {
  try {
    const { ancienMotDePasse, nouveauMotDePasse } = req.body;
    const r = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    const isValid = await bcrypt.compare(ancienMotDePasse, r.rows[0].mot_de_passe);
    if (!isValid) return res.status(401).json({ message: 'Ancien mot de passe incorrect.' });
    const hashed = await bcrypt.hash(nouveauMotDePasse, 10);
    await pool.query('UPDATE users SET mot_de_passe = $1 WHERE id = $2', [hashed, req.user.id]);
    return res.status(200).json({ message: 'Mot de passe mis a jour.' });
  } catch (err) {
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

module.exports = { login, setupPassword, me, changePassword };
