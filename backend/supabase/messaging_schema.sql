-- ============================================================
-- ScolarHub — Schéma messagerie & canaux (Supabase SQL Editor)
-- Exécuter ce script dans : Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- ── Canaux de discussion ────────────────────────────────────
CREATE TABLE IF NOT EXISTS canaux (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type          VARCHAR(50) NOT NULL,
  -- administration | admin_filiere | bde | groupe_filiere
  nom           VARCHAR(255) NOT NULL,
  description   TEXT,
  filiere       VARCHAR(100),
  etablissement_id INTEGER,
  lecture_seule BOOLEAN DEFAULT false,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_canaux_type ON canaux(type);
CREATE INDEX IF NOT EXISTS idx_canaux_filiere ON canaux(filiere);
CREATE INDEX IF NOT EXISTS idx_canaux_etablissement ON canaux(etablissement_id);

-- ── Conversations privées (étudiant ↔ admin) ────────────────
CREATE TABLE IF NOT EXISTS conversations (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type          VARCHAR(30) DEFAULT 'prive_admin',
  etudiant_id   UUID NOT NULL,
  admin_id      UUID,
  sujet         VARCHAR(255),
  statut        VARCHAR(20) DEFAULT 'ouvert',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_conversations_etudiant ON conversations(etudiant_id);

-- ── Messages (canal ou conversation privée) ─────────────────
CREATE TABLE IF NOT EXISTS messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  canal_id         UUID REFERENCES canaux(id) ON DELETE CASCADE,
  conversation_id  UUID REFERENCES conversations(id) ON DELETE CASCADE,
  auteur_id        UUID NOT NULL,
  contenu          TEXT NOT NULL,
  type             VARCHAR(20) DEFAULT 'texte',
  fichier_url      TEXT,
  epingle          BOOLEAN DEFAULT false,
  reactions        JSONB DEFAULT '{}',
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT message_cible CHECK (
    (canal_id IS NOT NULL AND conversation_id IS NULL)
    OR (canal_id IS NULL AND conversation_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_messages_canal ON messages(canal_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_auteur ON messages(auteur_id);

-- ── Notifications in-app ────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL,
  titre      VARCHAR(255) NOT NULL,
  corps      TEXT,
  type       VARCHAR(50) DEFAULT 'info',
  data       JSONB DEFAULT '{}',
  lue        BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id, created_at DESC);

-- ── Canaux par défaut (IST Ouaga 2000) ──────────────────────
-- Adapter filiere / etablissement_id selon votre établissement
INSERT INTO canaux (type, nom, description, filiere, etablissement_id, lecture_seule)
SELECT * FROM (VALUES
  ('administration'::VARCHAR, 'Administration'::VARCHAR,
   'Annonces officielles et informations pédagogiques'::TEXT,
   NULL::VARCHAR, 1::INTEGER, true),
  ('admin_filiere', 'Admin & Filière — Réseaux et Télécoms',
   'Messages ciblés Admin+Délégué → filière RT',
   'Réseaux et Télécoms', 1, false),
  ('bde', 'Bureau des Étudiants',
   'Actualités et événements du BDE',
   NULL, 1, false),
  ('groupe_filiere', 'Groupe Filière — Réseaux et Télécoms',
   'Discussion privée entre étudiants de la filière',
   'Réseaux et Télécoms', 1, false)
) AS v(type, nom, description, filiere, etablissement_id, lecture_seule)
WHERE NOT EXISTS (SELECT 1 FROM canaux LIMIT 1);

-- Désactiver RLS pour le backend (service_role) — option dev
-- En production, configurer des policies Supabase appropriées
ALTER TABLE canaux ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policy permissive pour service_role / anon key backend
CREATE POLICY "Backend full access canaux" ON canaux FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Backend full access messages" ON messages FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Backend full access conversations" ON conversations FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Backend full access notifications" ON notifications FOR ALL USING (true) WITH CHECK (true);
