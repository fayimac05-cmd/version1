-- Suppression des anciennes tables pour éviter les erreurs d'existence
DROP TABLE IF EXISTS notifications CASCADE;
DROP TABLE IF EXISTS edt CASCADE;
DROP TABLE IF EXISTS annonces CASCADE;
DROP TABLE IF EXISTS etablissements CASCADE;
DROP TABLE IF EXISTS evaluations_professeurs CASCADE;
DROP TABLE IF EXISTS notes CASCADE;
DROP TABLE IF EXISTS sessions_notes CASCADE;
DROP TABLE IF EXISTS supports_cours CASCADE;
DROP TABLE IF EXISTS reactions CASCADE;
DROP TABLE IF EXISTS messages_groupe CASCADE;
DROP TABLE IF EXISTS messages_prives CASCADE;
DROP TABLE IF EXISTS messages CASCADE;
DROP TABLE IF EXISTS canal_membres CASCADE;
DROP TABLE IF EXISTS canaux CASCADE;
DROP TABLE IF EXISTS ia_conversations CASCADE;
DROP TABLE IF EXISTS reclamations CASCADE;
DROP TABLE IF EXISTS tickets CASCADE;
DROP TABLE IF EXISTS etudiants CASCADE;
DROP TABLE IF EXISTS membres CASCADE;
DROP TABLE IF EXISTS module_professeur CASCADE;
DROP TABLE IF EXISTS modules CASCADE;
DROP TABLE IF EXISTS professeurs CASCADE;
DROP TABLE IF EXISTS filieres CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- Suppression des tables résiduelles d'un autre projet (non liées à ScolarHub)
DROP TABLE IF EXISTS announcements CASCADE;
DROP TABLE IF EXISTS banners CASCADE;
DROP TABLE IF EXISTS grades CASCADE;
DROP TABLE IF EXISTS library CASCADE;
DROP TABLE IF EXISTS niveaux CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS schedule CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS messages_canal CASCADE;
DROP TABLE IF EXISTS cours_ressources CASCADE;
DROP TABLE IF EXISTS cours_supports CASCADE;

-- Extension pour générer des UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Table des utilisateurs (Connexion et profil commun)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    matricule VARCHAR(50) UNIQUE,
    nom VARCHAR(255) NOT NULL,
    prenoms VARCHAR(255),
    email VARCHAR(255) UNIQUE,
    tel VARCHAR(50),
    mot_de_passe VARCHAR(255),
    role VARCHAR(50) NOT NULL,
    statut VARCHAR(50) DEFAULT 'actif',
    domaine VARCHAR(255),
    niveau VARCHAR(50),
    date_naissance VARCHAR(50),
    nationalite VARCHAR(100) DEFAULT 'Burkinabè',
    adresse TEXT,
    nom_parent VARCHAR(255),
    tel_parent VARCHAR(50),
    email_parent VARCHAR(255),
    etudiant_role VARCHAR(50) DEFAULT 'etudiant',
    filiere_role VARCHAR(255),
    filiere_nom VARCHAR(255)
);

-- Table des filières
CREATE TABLE filieres (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT
);

-- Table des professeurs
CREATE TABLE professeurs (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    specialite VARCHAR(255)
);

-- Table des modules
CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    coefficient DECIMAL DEFAULT 1,
    volume_horaire INTEGER,
    filiere_id INTEGER REFERENCES filieres(id) ON DELETE CASCADE,
    filiere_nom VARCHAR(255)
);

-- Table de liaison Modules - Professeurs
CREATE TABLE module_professeur (
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
    professeur_id INTEGER REFERENCES professeurs(id) ON DELETE CASCADE,
    PRIMARY KEY (module_id, professeur_id)
);

-- Table des membres
CREATE TABLE membres (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    permissions JSONB DEFAULT '[]'
);

-- Table des étudiants (infos lisibles directement dans Supabase)
CREATE TABLE etudiants (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    filiere_id INTEGER REFERENCES filieres(id),
    premiereFois BOOLEAN DEFAULT TRUE,
    matricule VARCHAR(50),
    nom VARCHAR(255),
    prenoms VARCHAR(255),
    email VARCHAR(255),
    tel VARCHAR(50),
    filiere_nom VARCHAR(255),
    domaine VARCHAR(255),
    niveau VARCHAR(50),
    date_naissance VARCHAR(50),
    nationalite VARCHAR(100) DEFAULT 'Burkinabè',
    adresse TEXT,
    nom_parent VARCHAR(255),
    tel_parent VARCHAR(50),
    email_parent VARCHAR(255),
    statut VARCHAR(50) DEFAULT 'actif'
);

-- Table des notes
CREATE TABLE notes (
    id SERIAL PRIMARY KEY,
    etudiant_id INTEGER REFERENCES etudiants(id) ON DELETE CASCADE,
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
    valeur DECIMAL CHECK (valeur >= 0 AND valeur <= 20)
);

-- Table des évaluations professeurs
CREATE TABLE evaluations_professeurs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    etudiant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    professeur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    note INTEGER CHECK (note >= 1 AND note <= 5),
    commentaire TEXT,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (etudiant_id, professeur_id)
);

-- =========================================================================
-- ─── NOUVELLES TABLES AJOUTÉES ───────────────────────────────────────────
-- =========================================================================

-- Table des établissements (Campus)
CREATE TABLE etablissements (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    adresse VARCHAR(255),
    telephone VARCHAR(50),
    email VARCHAR(255)
);

-- Table des annonces
CREATE TABLE annonces (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titre VARCHAR(255) NOT NULL,
    contenu TEXT NOT NULL,
    filiere INTEGER REFERENCES filieres(id) ON DELETE SET NULL,
    filiere_nom VARCHAR(255),
    niveau VARCHAR(50),
    "cibleRole" VARCHAR(50) NOT NULL,
    statut VARCHAR(50) DEFAULT 'brouillon',
    fichiers JSONB DEFAULT '[]',
    auteur UUID REFERENCES users(id) ON DELETE SET NULL,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des emplois du temps (EDT)
CREATE TABLE edt (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filiere INTEGER REFERENCES filieres(id) ON DELETE CASCADE,
    filiere_nom VARCHAR(255),
    niveau VARCHAR(50) NOT NULL,
    "anneeAcademique" VARCHAR(50) NOT NULL,
    "pdfUrl" VARCHAR(255) NOT NULL,
    archive BOOLEAN DEFAULT FALSE,
    "archivedAt" TIMESTAMP,
    "createdAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    titre VARCHAR(255) NOT NULL,
    corps TEXT NOT NULL,
    lue BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des sessions de notes
CREATE TABLE sessions_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filiere_id INTEGER REFERENCES filieres(id) ON DELETE CASCADE,
    filiere_nom VARCHAR(255),
    niveau VARCHAR(50),
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
    professeur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    date_session TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_sent BOOLEAN DEFAULT FALSE
);

-- Table des supports de cours
CREATE TABLE supports_cours (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    filiere_id INTEGER REFERENCES filieres(id) ON DELETE CASCADE,
    filiere_nom VARCHAR(255),
    niveau VARCHAR(50),
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
    professeur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    fichier_url VARCHAR(500) NOT NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================================
-- ─── TABLES MESSAGERIE ──────────────────────────────────────────────────
-- =========================================================================

-- Table des canaux de discussion
CREATE TABLE canaux (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(50) DEFAULT 'general',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table de liaison canaux - membres
CREATE TABLE canal_membres (
    canal_id INTEGER REFERENCES canaux(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) DEFAULT 'membre',
    PRIMARY KEY (canal_id, user_id)
);

-- Table des messages dans les canaux
CREATE TABLE messages (
    id SERIAL PRIMARY KEY,
    canal_id INTEGER REFERENCES canaux(id) ON DELETE CASCADE,
    auteur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'canal',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des messages privés
CREATE TABLE messages_prives (
    id SERIAL PRIMARY KEY,
    expediteur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    destinataire_id UUID REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des messages de groupe filière
CREATE TABLE messages_groupe (
    id SERIAL PRIMARY KEY,
    filiere_id INTEGER REFERENCES filieres(id) ON DELETE CASCADE,
    auteur_id UUID REFERENCES users(id) ON DELETE CASCADE,
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des réactions
CREATE TABLE reactions (
    id SERIAL PRIMARY KEY,
    message_id INTEGER NOT NULL,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    emoji VARCHAR(50) NOT NULL,
    message_type VARCHAR(50) DEFAULT 'canal',
    UNIQUE (message_id, user_id, emoji)
);

-- =========================================================================
-- ─── TABLE CONVERSATIONS IA ─────────────────────────────────────────────
-- =========================================================================

-- Table pour l'historique des conversations IA
CREATE TABLE ia_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    role VARCHAR(50) NOT NULL,
    contenu TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================================
-- ─── TABLE RÉCLAMATIONS ─────────────────────────────────────────────────
-- =========================================================================

CREATE TABLE reclamations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    etudiant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    module_id UUID,
    type VARCHAR(255) NOT NULL,
    statut VARCHAR(50) DEFAULT 'en_attente',
    justification TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- =========================================================================
-- ─── TABLE TICKETS SUPPORT ──────────────────────────────────────────────
-- =========================================================================

CREATE TABLE tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    etudiant_id UUID REFERENCES users(id) ON DELETE CASCADE,
    montant NUMERIC NOT NULL,
    statut VARCHAR(50) DEFAULT 'en_attente',
    qr_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

