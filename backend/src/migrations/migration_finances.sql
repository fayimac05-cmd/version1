-- ============================================================================
-- ScolarHub — Module FINANCES (scolarité, inscription, tranches, dépenses)
-- Script ADDITIF et relançable : il ne modifie ni ne supprime aucune table
-- existante (frais_scolarite et paiements restent tels quels).
-- Les types des clés (etudiants.id, filieres.id) sont lus dans ta base,
-- donc le script marche que ces id soient des entiers ou des UUID.
-- ============================================================================
DO $$
DECLARE
  t_etud  TEXT;
  t_fil   TEXT;
BEGIN
  SELECT format_type(a.atttypid, a.atttypmod) INTO t_etud
    FROM pg_attribute a WHERE a.attrelid = 'public.etudiants'::regclass
     AND a.attname = 'id' AND NOT a.attisdropped;
  SELECT format_type(a.atttypid, a.atttypmod) INTO t_fil
    FROM pg_attribute a WHERE a.attrelid = 'public.filieres'::regclass
     AND a.attname = 'id' AND NOT a.attisdropped;

  -- 1) Grille tarifaire : un montant par domaine / filière / niveau
  --    (NULL = « tous »). type = inscription | scolarite | autre.
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS finance_grilles (
      id               SERIAL PRIMARY KEY,
      etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
      annee_academique TEXT    NOT NULL,
      type             TEXT    NOT NULL DEFAULT 'scolarite',
      libelle          TEXT    NOT NULL,
      domaine          TEXT,
      filiere_id       %s,
      niveau           TEXT,
      montant_total    NUMERIC(14,0) NOT NULL CHECK (montant_total >= 0),
      actif            BOOLEAN NOT NULL DEFAULT TRUE,
      created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )$f$, t_fil);

  -- 2) Tranches de chaque ligne de la grille (échéancier)
  CREATE TABLE IF NOT EXISTS finance_tranches (
    id         SERIAL PRIMARY KEY,
    grille_id  INTEGER NOT NULL REFERENCES finance_grilles(id) ON DELETE CASCADE,
    numero     INTEGER NOT NULL,
    libelle    TEXT,
    montant    NUMERIC(14,0) NOT NULL CHECK (montant > 0),
    echeance   DATE
  );

  -- 3) Remises / bourses accordées à un étudiant (réduisent ce qu'il doit)
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS finance_remises (
      id               SERIAL PRIMARY KEY,
      etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
      etudiant_id      %s NOT NULL,
      annee_academique TEXT NOT NULL,
      montant          NUMERIC(14,0) NOT NULL CHECK (montant > 0),
      motif            TEXT,
      created_by       TEXT,
      created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )$f$, t_etud);

  -- 4) Versements (argent reçu). Une ligne par paiement, saisi par l'admin
  --    ou fait en ligne (Orange Money, Moov, Wave...).
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS finance_versements (
      id               SERIAL PRIMARY KEY,
      etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
      etudiant_id      %s NOT NULL,
      annee_academique TEXT NOT NULL,
      montant          NUMERIC(14,0) NOT NULL CHECK (montant > 0),
      mode             TEXT NOT NULL DEFAULT 'especes',
      operateur        TEXT,
      telephone        TEXT,
      reference        TEXT,
      transaction_id   TEXT,
      statut           TEXT NOT NULL DEFAULT 'reussi',
      numero_recu      TEXT,
      note             TEXT,
      motif_annulation TEXT,
      enregistre_par   TEXT,
      created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      confirmed_at     TIMESTAMPTZ
    )$f$, t_etud);

  -- 5) Relances envoyées (historique + message affiché à l'étudiant/parent)
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS finance_relances (
      id               SERIAL PRIMARY KEY,
      etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
      etudiant_id      %s NOT NULL,
      message          TEXT NOT NULL,
      canaux           TEXT[] NOT NULL DEFAULT '{}',
      envoye_par       TEXT,
      created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )$f$, t_etud);

  -- 6) Blocage de l'accès aux notes et au bulletin (décidé par l'administration)
  EXECUTE format($f$
    CREATE TABLE IF NOT EXISTS finance_blocages (
      etudiant_id      %s PRIMARY KEY,
      etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
      bloque           BOOLEAN NOT NULL DEFAULT TRUE,
      motif            TEXT,
      par              TEXT,
      depuis           TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )$f$, t_etud);

  -- 7) Dépenses de l'établissement
  CREATE TABLE IF NOT EXISTS finance_depenses (
    id               SERIAL PRIMARY KEY,
    etablissement_id INTEGER NOT NULL REFERENCES etablissements(id),
    libelle          TEXT NOT NULL,
    categorie        TEXT NOT NULL DEFAULT 'autre',
    montant          NUMERIC(14,0) NOT NULL CHECK (montant > 0),
    date_depense     DATE NOT NULL DEFAULT CURRENT_DATE,
    beneficiaire     TEXT,
    justificatif_url TEXT,
    created_by       TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
  );
END $$;

CREATE INDEX IF NOT EXISTS finance_grilles_etab_idx     ON finance_grilles (etablissement_id, annee_academique);
CREATE INDEX IF NOT EXISTS finance_tranches_grille_idx  ON finance_tranches (grille_id, numero);
CREATE INDEX IF NOT EXISTS finance_versements_etud_idx  ON finance_versements (etudiant_id, annee_academique);
CREATE INDEX IF NOT EXISTS finance_versements_etab_idx  ON finance_versements (etablissement_id, created_at);
CREATE INDEX IF NOT EXISTS finance_remises_etud_idx     ON finance_remises (etudiant_id, annee_academique);
CREATE INDEX IF NOT EXISTS finance_relances_etud_idx    ON finance_relances (etudiant_id, created_at DESC);
CREATE INDEX IF NOT EXISTS finance_depenses_etab_idx    ON finance_depenses (etablissement_id, date_depense);
