const { Pool } = require('pg');
require('dotenv').config();
const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     parseInt(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME,
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  ssl:      { rejectUnauthorized: false },
});
pool.connect((err) => {
  if (err) console.error('Erreur connexion PostgreSQL :', err.message, '(' + err.code + ')');
  else     console.log('Connecte a PostgreSQL — scolarhub');
});
pool.on('error', (err, client) => {
  console.error('Erreur inattendue sur le client PostgreSQL idle', err);
});

module.exports = pool;
