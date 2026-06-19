const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

const genToken = (user) => jwt.sign(
  { id: user.id, matricule: user.matricule, role: user.role, filiere_id: user.filiere_id },
  process.env.JWT_SECRET,
  { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
);

const login = async (req, res) => {
  try {
    const { matricule, nom, tel, motDePasse } = req.body;
    let user;

    if (matricule) {
      const r = await pool.query('SELECT u.*, e.filiere_id FROM users u LEFT JOIN etudiants e ON u.id = e.user_id WHERE u.matricule = $1', [matricule.trim().toUpperCase()]);
      user = r.rows[0];
    } else if (nom && tel) {
      const r = await pool.query('SELECT u.*, e.filiere_id FROM users u LEFT JOIN etudiants e ON u.id = e.user_id WHERE LOWER(u.nom) = LOWER($1) AND u.tel = $2', [nom.trim(), tel.trim()]);
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
      user: { id: user.id, nom: user.nom, prenoms: user.prenoms, matricule: user.matricule, role: user.role, filiere_id: user.filiere_id, statut: user.statut },
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
    const r = await pool.query('SELECT u.*, e.filiere_id FROM users u LEFT JOIN etudiants e ON u.id = e.user_id WHERE u.id = $1', [userId]);
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
      'SELECT u.id, u.nom, u.prenoms, u.matricule, u.email, u.tel, u.role, u.statut, e.filiere_id FROM users u LEFT JOIN etudiants e ON u.id = e.user_id WHERE u.id = $1',
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
    if (!ancienMotDePasse || !nouveauMotDePasse) {
      return res.status(400).json({ message: 'Ancien et nouveau mot de passe requis.' });
    }
    const r = await pool.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    if (!r.rows[0]) {
      return res.status(404).json({ message: 'Utilisateur introuvable.' });
    }
    if (!r.rows[0].mot_de_passe) {
      return res.status(400).json({ message: 'Aucun mot de passe configuré. Utilisez la configuration initiale.' });
    }
    const isValid = await bcrypt.compare(ancienMotDePasse, r.rows[0].mot_de_passe);
    if (!isValid) return res.status(401).json({ message: 'Ancien mot de passe incorrect.' });
    const hashed = await bcrypt.hash(nouveauMotDePasse, 10);
    await pool.query('UPDATE users SET mot_de_passe = $1 WHERE id = $2', [hashed, req.user.id]);
    return res.status(200).json({ message: 'Mot de passe mis a jour.' });
  } catch (err) {
    console.error('Change password error:', err);
    return res.status(500).json({ message: 'Erreur serveur.' });
  }
};

const register = async (req, res) => {
  let client;
  try {
    const { nom, prenoms, email, telephone, motDePasse, matricule: matriculeBody } = req.body;

    if (!nom?.trim() || !prenoms?.trim()) {
      return res.status(400).json({ message: 'Nom et prenom requis.' });
    }
    if (!motDePasse || motDePasse.length < 4) {
      return res.status(400).json({ message: 'Mot de passe requis (4 caracteres minimum).' });
    }

    client = await pool.connect();

    await client.query('BEGIN');

    // Generate matricule if not provided
    let matricule = matriculeBody?.trim().toUpperCase();
    if (!matricule) {
      const annee = new Date().getFullYear().toString().slice(2);
      const countRes = await client.query("SELECT COUNT(*)::int AS c FROM users WHERE role = 'etudiant'");
      let num = 1900 + countRes.rows[0].c + 1;
      matricule = `${annee}IST-O2/${num}`;
      let exists = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
      while (exists.rows.length > 0) {
        num += 1;
        matricule = `${annee}IST-O2/${num}`;
        exists = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
      }
    }

    // Check uniqueness
    const existingUser = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
    if (existingUser.rows.length > 0) {
      await client.query('ROLLBACK');
      return res.status(409).json({ message: 'Ce matricule est deja utilise.' });
    }

    if (email?.trim()) {
      const existingEmail = await client.query('SELECT 1 FROM users WHERE email = $1', [email.trim()]);
      if (existingEmail.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ message: 'Cet email est deja utilise.' });
      }
    }

    const hashed = await bcrypt.hash(motDePasse, 10);

    const userRes = await client.query(
      `INSERT INTO users (matricule, nom, prenoms, email, tel, role, statut, mot_de_passe)
       VALUES ($1, $2, $3, $4, $5, 'etudiant', 'actif', $6) RETURNING *`,
      [matricule, nom.trim().toUpperCase(), prenoms.trim(), email?.trim() || null, telephone?.trim() || null, hashed]
    );
    const user = userRes.rows[0];

    // Create etudiants record
    await client.query(
      `INSERT INTO etudiants (user_id, premierefois, matricule, nom, prenoms, email, tel, statut)
       VALUES ($1, false, $2, $3, $4, $5, $6, 'actif')`,
      [user.id, matricule, nom.trim().toUpperCase(), prenoms.trim(), email?.trim() || null, telephone?.trim() || null]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      token: genToken(user),
      user: { id: user.id, nom: user.nom, prenoms: user.prenoms, matricule: user.matricule, role: user.role, statut: user.statut },
    });
  } catch (err) {
    if (client) {
      try { await client.query('ROLLBACK'); } catch (_) {}
    }
    console.error('Register error:', err);
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Matricule ou email deja utilise.' });
    }
    return res.status(500).json({ message: 'Erreur serveur.' });
  } finally {
    if (client) client.release();
  }
};

module.exports = { login, setupPassword, me, changePassword, register };
