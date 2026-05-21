const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Récupération des variables d'environnement Supabase
const supabaseUrl = process.env.SUPABASE_URL || 'https://votre-projet.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY || 'votre-anon-key';

if (!process.env.SUPABASE_URL || !process.env.SUPABASE_ANON_KEY) {
  console.warn(
    "⚠️ [Warning] Les variables d'environnement SUPABASE_URL ou SUPABASE_ANON_KEY ne sont pas définies dans le fichier .env. " +
    "Utilisation des valeurs par défaut pour le développement."
  );
}

// Initialisation du client Supabase
const supabase = createClient(supabaseUrl, supabaseKey);

console.log('✅ Client Supabase configuré avec succès');

module.exports = supabase;
