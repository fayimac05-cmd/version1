-- Table des filières
CREATE TABLE filieres (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    description TEXT
);

-- Table des professeurs
CREATE TABLE professeurs (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    specialite VARCHAR(255)
);

-- Table des modules
CREATE TABLE modules (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    coefficient DECIMAL DEFAULT 1,
    volume_horaire INTEGER,
    filiere_id INTEGER REFERENCES filieres(id) ON DELETE CASCADE
);

-- Table de liaison Modules - Professeurs
CREATE TABLE module_professeur (
    module_id INTEGER REFERENCES modules(id) ON DELETE CASCADE,
    professeur_id INTEGER REFERENCES professeurs(id) ON DELETE CASCADE,
    PRIMARY KEY (module_id, professeur_id)
);

-- Table des membres (Admin / Scolarité)
CREATE TABLE membres (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- 'admin', 'scolarite', 'direction'
    permissions JSONB DEFAULT '[]'
);

-- Table des étudiants
CREATE TABLE etudiants (
    id SERIAL PRIMARY KEY,
    nom VARCHAR(255) NOT NULL,
    filiere_id INTEGER REFERENCES filieres(id)
);

-- Table des notes (pour les statistiques)
CREATE TABLE notes (
    id SERIAL PRIMARY KEY,
    etudiant_id INTEGER REFERENCES etudiants(id),
    module_id INTEGER REFERENCES modules(id),
    valeur DECIMAL CHECK (valeur >= 0 AND valeur <= 20)
);
