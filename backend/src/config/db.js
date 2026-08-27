const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host:     process.env.DB_HOST,
  port:     process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'postgres',
  user:     process.env.DB_USER,
  password: process.env.DB_PASS,
  ssl: false,
  keepAlive: true,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
  max: 5,
});

pool.on('error', (err) => {
  console.error('Erreur pool PostgreSQL:', err.message);
});

pool.connect((err, client, release) => {
  if (err) console.error('Erreur connexion PostgreSQL :', err.message);
  else {
    console.log('Connecte a PostgreSQL — scolarhub');
    release();
  }
});

module.exports = pool;
