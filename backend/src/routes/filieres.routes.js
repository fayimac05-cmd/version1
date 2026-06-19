const express = require('express');
const router = express.Router();
const pool = require('../config/db');
const { ensureFilieres } = require('../utils/filieres');

router.get('/', async (req, res) => {
  let client;
  try {
    client = await pool.connect();
    await ensureFilieres(client);
    const result = await client.query('SELECT id, nom, description FROM filieres ORDER BY nom');
    return res.status(200).json(result.rows);
  } catch (err) {
    console.error('[filieres]', err.message);
    return res.status(500).json({ message: 'Erreur chargement filieres.' });
  } finally {
    if (client) client.release();
  }
});

module.exports = router;
