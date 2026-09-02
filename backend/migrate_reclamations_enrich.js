const { Pool } = require('pg');
require('dotenv').config();

const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  ssl: process.env.DB_SSL === 'false' ? false : { rejectUnauthorized: false },
});

const query = `
-- module_id : texte pour compatibilité modules (INTEGER)
DO $$ BEGIN
  ALTER TABLE reclamations ALTER COLUMN module_id TYPE TEXT USING module_id::text;
EXCEPTION WHEN others THEN NULL;
END $$;

ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS module_nom VARCHAR(255);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS type_eval VARCHAR(100);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS parties_contestees TEXT;
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS note_actuelle NUMERIC(4,2);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS semestre VARCHAR(80);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS annee VARCHAR(20);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS filiere VARCHAR(255);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS photo_url TEXT;
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS reponse TEXT;
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS prof_transfere VARCHAR(255);
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS date_traitement TIMESTAMP WITH TIME ZONE;
ALTER TABLE reclamations ADD COLUMN IF NOT EXISTS modules_contestes JSONB;
`;

pool.connect(async (err, client, release) => {
  if (err) {
    console.error('Error connecting:', err.stack);
    process.exit(1);
  }
  try {
    console.log('Connected to database!');
    await client.query(query);
    console.log('Table reclamations enrichie avec succès.');
  } catch (errQuery) {
    console.error('Error running query:', errQuery);
    process.exit(1);
  } finally {
    release();
    await pool.end();
  }
});
