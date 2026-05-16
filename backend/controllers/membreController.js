const db = require('../config/db');
const bcrypt = require('bcryptjs');

exports.createMembre = async (req, res) => {
  const { email, password, role, permissions } = req.body;
  try {
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await db.query(
      'INSERT INTO membres (email, password, role, permissions) VALUES ($1, $2, $3, $4) RETURNING id, email, role, permissions',
      [email, hashedPassword, role, JSON.stringify(permissions)]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.getAllMembres = async (req, res) => {
  try {
    const result = await db.query('SELECT id, email, role, permissions FROM membres');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.updatePermissions = async (req, res) => {
  const { id } = req.params;
  const { permissions } = req.body;
  try {
    const result = await db.query(
      'UPDATE membres SET permissions = $1 WHERE id = $2 RETURNING id, email, role, permissions',
      [JSON.stringify(permissions), id]
    );
    if (result.rows.length === 0) return res.status(440).json({ error: 'Membre non trouvé' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

exports.deleteMembre = async (req, res) => {
  const { id } = req.params;
  try {
    await db.query('DELETE FROM membres WHERE id = $1', [id]);
    res.json({ message: 'Membre supprimé avec succès' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};
