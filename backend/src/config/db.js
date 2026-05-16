const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST || 'localhost',
  port:     process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'scolarhub',
  user:     process.env.DB_USER || 'postgres',
  password: process.env.DB_PASS || 'postgres',
});

pool.connect((err) => {
  if (err) console.error('Erreur connexion PostgreSQL :', err.message);
  else     console.log('Connecté à PostgreSQL — scolarhub');
});

module.exports = pool;
