-- ScolarHub — Finances, lot « caisse » : clôture de caisse, canal, reçus.
-- Relançable sans risque. À exécuter dans l'éditeur SQL de Supabase.

ALTER TABLE finance_versements ADD COLUMN IF NOT EXISTS canal TEXT NOT NULL DEFAULT 'caisse';
ALTER TABLE finance_versements ADD COLUMN IF NOT EXISTS recu_impressions INTEGER NOT NULL DEFAULT 0;
ALTER TABLE finance_versements ADD COLUMN IF NOT EXISTS cloture_id INTEGER;

-- Les paiements déjà faits en ligne (avec un numéro de téléphone) ne sont pas des paiements de caisse.
UPDATE finance_versements SET canal = 'en_ligne' WHERE telephone IS NOT NULL AND canal = 'caisse';

CREATE TABLE IF NOT EXISTS finance_clotures (
  id               SERIAL PRIMARY KEY,
  etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
  date_caisse      DATE NOT NULL,
  caissier         TEXT NOT NULL,
  nb_versements    INTEGER NOT NULL DEFAULT 0,
  attendu_especes  NUMERIC(14,0) NOT NULL DEFAULT 0,
  compte_especes   NUMERIC(14,0) NOT NULL DEFAULT 0,
  ecart            NUMERIC(14,0) NOT NULL DEFAULT 0,
  autres_modes     NUMERIC(14,0) NOT NULL DEFAULT 0,
  note             TEXT,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS finance_clotures_etab_idx ON finance_clotures (etablissement_id, date_caisse);
CREATE INDEX IF NOT EXISTS finance_versements_canal_idx ON finance_versements (etablissement_id, canal, statut);
