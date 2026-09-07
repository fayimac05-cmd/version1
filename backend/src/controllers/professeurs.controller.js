const db = require('../config/db');
const bcrypt = require('bcryptjs');

// ── GET /api/professeurs ──────────────────────────────────────────────────────
// Renvoie chaque professeur avec ses affectations (filière + niveau), agrégées.
exports.getAllProfesseurs = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.nom, u.prenoms, u.email, u.tel, u.statut, u.domaine,
              COALESCE(
                json_agg(
                  json_build_object('filiere_id', f.id, 'filiere_nom', f.nom, 'niveau', pf.niveau)
                  ORDER BY f.nom, pf.niveau
                ) FILTER (WHERE pf.id IS NOT NULL), '[]'
              ) AS affectations
       FROM users u
       LEFT JOIN professeur_filieres pf ON pf.professeur_id = u.id
       LEFT JOIN filieres f ON f.id = pf.filiere_id
       WHERE u.role = 'professeur'
       GROUP BY u.id, u.nom, u.prenoms, u.email, u.tel, u.statut, u.domaine
       ORDER BY u.nom ASC`
    );
    res.json(result.rows);
  } catch (err) {
    console.error('getAllProfesseurs:', err.message);
    res.status(500).json({ error: err.message });
  }
};

// ── GET /api/professeurs/lookup?nom=X&tel=Y ───────────────────────────────────
// Conservé pour compatibilité mais la connexion prof passe désormais par
// /api/auth/lookup (générique, gère nom+prénom+tel pour tous les rôles).
exports.lookupProfesseur = async (req, res) => {
  try {
    const { nom, tel, matricule } = req.query;
    let user = null;

    if (matricule) {
      const r = await db.query(
        `SELECT id, nom, prenoms, matricule, role, statut, domaine,
                mot_de_passe IS NOT NULL AS a_mot_de_passe
         FROM users WHERE matricule = $1 AND role = 'professeur'`,
        [matricule.trim().toUpperCase()]
      );
      user = r.rows[0];
    } else if (nom && tel) {
      const r = await db.query(
        `SELECT id, nom, prenoms, matricule, role, statut, domaine,
                mot_de_passe IS NOT NULL AS a_mot_de_passe
         FROM users WHERE LOWER(nom) = LOWER($1) AND tel = $2 AND role = 'professeur'`,
        [nom.trim(), tel.trim()]
      );
      user = r.rows[0];
    } else {
      return res.status(400).json({ found: false, message: 'Matricule ou nom+tel requis.' });
    }

    if (!user) return res.status(404).json({ found: false, message: 'Professeur introuvable.' });
    if (user.statut === 'suspendu') return res.status(403).json({ found: false, message: 'Compte suspendu.' });

    return res.status(200).json({
      found: true,
      premierLogin: !user.a_mot_de_passe,
      userId: user.id,
      user: {
        id: user.id, nom: user.nom, prenoms: user.prenoms,
        matricule: user.matricule, role: user.role,
        domaine: user.domaine || '',
      },
    });
  } catch (err) {
    console.error('lookupProfesseur:', err.message);
    res.status(500).json({ found: false, message: 'Erreur serveur.' });
  }
};

// ── Utilitaire : remplace les affectations (filière + niveau) d'un prof ──────
const remplacerAffectations = async (client, professeurId, affectations) => {
  await client.query('DELETE FROM professeur_filieres WHERE professeur_id = $1', [professeurId]);
  if (!Array.isArray(affectations) || affectations.length === 0) return;
  for (const a of affectations) {
    const filiereId = a.filiere_id ?? a.filiereId;
    const niveau = a.niveau;
    if (!filiereId || !niveau) continue;
    await client.query(
      `INSERT INTO professeur_filieres (professeur_id, filiere_id, niveau)
       VALUES ($1, $2, $3) ON CONFLICT (professeur_id, filiere_id, niveau) DO NOTHING`,
      [professeurId, filiereId, niveau]
    );
  }
};

// ── POST /api/professeurs ─────────────────────────────────────────────────────
// Plus de matricule ni de mot de passe générés : le prof se connecte par
// nom+prénom+téléphone et définit son mot de passe à sa première connexion
// (comme les admins et les parents), via /api/auth/lookup puis /api/auth/login.
exports.createProfesseur = async (req, res) => {
  const { nom, prenoms, tel, email, domaines, affectations } = req.body;
  if (!nom || !prenoms || !tel) {
    return res.status(400).json({ error: 'nom, prenoms et tel sont obligatoires.' });
  }
  const client = await db.connect();
  try {
    const domaineStr = Array.isArray(domaines) ? domaines.join(',') : (domaines || null);

    // 1. Insérer dans users — sans matricule, sans mot de passe
    await client.query(
      `INSERT INTO users (nom, prenoms, email, tel, role, domaine, statut)
       VALUES ($1, $2, $3, $4, 'professeur', $5, 'actif')`,
      [nom.trim().toUpperCase(), prenoms.trim(), email?.trim() || null, tel.trim(), domaineStr]
    );

    // Récupérer l'utilisateur inséré (par tel, unique parmi les profs fraîchement créés)
    const userRow = await client.query(
      `SELECT id, nom, prenoms, email, tel, role, domaine, statut FROM users
       WHERE role = 'professeur' AND tel = $1 ORDER BY id DESC LIMIT 1`,
      [tel.trim()]
    );
    const user = userRow.rows[0];
    if (!user) throw new Error('Impossible de récupérer le professeur après insertion.');

    // 2. Table professeurs (fiche complémentaire)
    await client.query(
      `INSERT INTO professeurs (user_id, specialite) VALUES ($1, $2)`,
      [user.id, domaineStr]
    );

    // 3. Affectations filière + niveau (plusieurs possibles)
    await remplacerAffectations(client, user.id, affectations);

    res.status(201).json({
      message: 'Professeur créé avec succès. Il pourra se connecter avec son nom, prénom et numéro de téléphone.',
      professeur: user,
    });
  } catch (err) {
    console.error('createProfesseur:', err.message);
    if (err.code === '23505') return res.status(409).json({ error: 'Email déjà utilisé.' });
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
};

// ── PUT /api/professeurs/:id ──────────────────────────────────────────────────
exports.updateProfesseur = async (req, res) => {
  const { id } = req.params;
  const { nom, prenoms, email, tel, domaines, statut, affectations } = req.body;
  const client = await db.connect();
  try {
    const domaineStr = Array.isArray(domaines) ? domaines.join(',') : (domaines !== undefined ? domaines : null);

    await client.query(
      `UPDATE users SET nom=COALESCE($1,nom), prenoms=COALESCE($2,prenoms),
       email=COALESCE($3,email), tel=COALESCE($4,tel),
       domaine=COALESCE($5,domaine), statut=COALESCE($6,statut)
       WHERE id=$7 AND role='professeur'`,
      [nom, prenoms, email, tel, domaineStr, statut, id]
    );

    if (affectations !== undefined) {
      await remplacerAffectations(client, id, affectations);
    }

    const result = await client.query(
      `SELECT id, nom, prenoms, email, tel, role, domaine, statut FROM users WHERE id=$1 AND role='professeur'`,
      [id]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Professeur non trouvé.' });
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('updateProfesseur:', err.message);
    res.status(500).json({ error: err.message });
  } finally {
    client.release();
  }
};

// ── DELETE /api/professeurs/:id ───────────────────────────────────────────────
exports.deleteProfesseur = async (req, res) => {
  const { id } = req.params;
  try {
    await db.query(`UPDATE users SET statut='renvoye' WHERE id=$1 AND role='professeur'`, [id]);
    res.json({ message: 'Professeur désactivé.' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
};

// ── GET /api/professeurs/:id ──────────────────────────────────────────────────
exports.getProfesseurById = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.nom, u.prenoms, u.email, u.tel, u.role, u.domaine, u.statut,
              COALESCE(
                json_agg(
                  json_build_object('filiere_id', f.id, 'filiere_nom', f.nom, 'niveau', pf.niveau)
                  ORDER BY f.nom, pf.niveau
                ) FILTER (WHERE pf.id IS NOT NULL), '[]'
              ) AS affectations
       FROM users u
       LEFT JOIN professeur_filieres pf ON pf.professeur_id = u.id
       LEFT JOIN filieres f ON f.id = pf.filiere_id
       WHERE u.id=$1 AND u.role='professeur'
       GROUP BY u.id, u.nom, u.prenoms, u.email, u.tel, u.role, u.domaine, u.statut`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Professeur non trouvé.' });
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── GET /api/professeurs/profile ──────────────────────────────────────────────
exports.getProfile = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.nom, u.prenoms, u.email, u.tel, u.role, u.domaine, u.statut,
              COALESCE(
                json_agg(
                  json_build_object('filiere_id', f.id, 'filiere_nom', f.nom, 'niveau', pf.niveau)
                  ORDER BY f.nom, pf.niveau
                ) FILTER (WHERE pf.id IS NOT NULL), '[]'
              ) AS affectations
       FROM users u
       LEFT JOIN professeur_filieres pf ON pf.professeur_id = u.id
       LEFT JOIN filieres f ON f.id = pf.filiere_id
       WHERE u.id=$1
       GROUP BY u.id, u.nom, u.prenoms, u.email, u.tel, u.role, u.domaine, u.statut`,
      [req.user.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Profil introuvable.' });
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── PUT /api/professeurs/profile ──────────────────────────────────────────────
exports.updateProfile = async (req, res) => {
  const { email, tel, domaine } = req.body;
  try {
    await db.query(
      `UPDATE users SET email=COALESCE($1,email), tel=COALESCE($2,tel), domaine=COALESCE($3,domaine)
       WHERE id=$4`,
      [email, tel, domaine, req.user.id]
    );
    const result = await db.query(
      `SELECT id, nom, prenoms, email, tel, domaine FROM users WHERE id=$1`,
      [req.user.id]
    );
    res.json(result.rows[0]);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── GET /api/professeurs/classes ──────────────────────────────────────────────
exports.getClasses = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT DISTINCT f.id, f.nom, pf.niveau, f.domaine, COUNT(e.id)::int AS nb_etudiants
       FROM professeur_filieres pf
       JOIN filieres f ON f.id = pf.filiere_id
       LEFT JOIN etudiants e ON e.filiere_id = f.id AND e.niveau = pf.niveau
       WHERE pf.professeur_id = $1
       GROUP BY f.id, f.nom, pf.niveau, f.domaine
       ORDER BY f.nom, pf.niveau`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── GET /api/professeurs/modules ──────────────────────────────────────────────
exports.getModules = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT m.* FROM modules m JOIN module_professeur mp ON m.id=mp.module_id WHERE mp.professeur_id=$1`,
      [req.user.id]
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── GET /api/professeurs/:id/modules ──────────────────────────────────────────
exports.getModulesByProfesseur = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT m.* FROM modules m JOIN module_professeur mp ON m.id=mp.module_id WHERE mp.professeur_id=$1`,
      [req.params.id]
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── GET /api/professeurs/classes/:filiere_id/students ─────────────────────────
exports.getStudentsByFiliere = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT u.id, u.nom, u.prenoms, u.matricule, u.email, u.tel, u.statut
       FROM users u LEFT JOIN etudiants e ON e.user_id=u.id
       WHERE e.filiere_id=$1 AND (u.role ILIKE '%etudiant%' OR u.role ILIKE '%delegue%' OR u.role ILIKE '%bde%') ORDER BY u.nom`,
      [req.params.filiere_id]
    );
    res.json(result.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── Disponibilités ────────────────────────────────────────────────────────────
exports.getDisponibilites = async (req, res) => {
  try {
    const r = await db.query('SELECT disponibilites FROM users WHERE id=$1', [req.user.id]);
    res.json(r.rows[0]?.disponibilites || []);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

exports.getAllDisponibilites = async (req, res) => {
  try {
    const r = await db.query(
      `SELECT id, nom, prenoms, disponibilites FROM users WHERE role='professeur' AND disponibilites IS NOT NULL`
    );
    res.json(r.rows);
  } catch (err) { res.status(500).json({ error: err.message }); }
};

exports.saveDisponibilites = async (req, res) => {
  try {
    await db.query('UPDATE users SET disponibilites=$1 WHERE id=$2', [JSON.stringify(req.body.disponibilites), req.user.id]);
    res.json({ message: 'Disponibilités enregistrées.' });
  } catch (err) { res.status(500).json({ error: err.message }); }
};

// ── PATCH /api/professeurs/assign-module ──────────────────────────────────────
exports.patchModuleAssignment = async (req, res) => {
  const { module_id, professeur_id, action } = req.body;
  try {
    if (action === 'assign') {
      await db.query('INSERT INTO module_professeur (module_id, professeur_id) VALUES ($1,$2) ON CONFLICT DO NOTHING', [module_id, professeur_id]);
    } else if (action === 'remove') {
      await db.query('DELETE FROM module_professeur WHERE module_id=$1 AND professeur_id=$2', [module_id, professeur_id]);
    } else {
      return res.status(400).json({ error: 'Action invalide.' });
    }
    res.json({ message: `Module ${action === 'assign' ? 'assigné' : 'retiré'} avec succès.` });
  } catch (err) { res.status(500).json({ error: err.message }); }
};
