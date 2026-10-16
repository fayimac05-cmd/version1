// ============================================================
// src/controllers/plateforme.controller.js
// Espace PROPRIÉTAIRE DE LA PLATEFORME (Nexilys) : création et gestion des
// établissements. Protégé par une clé secrète (PLATFORM_ADMIN_KEY), pas par
// un compte d'établissement — voir plateforme.routes.js.
// ============================================================
const bcrypt = require('bcryptjs');
const pool = require('../config/db');
const { compilerModele, modeleValide } = require('../utils/matricule');
const { ensureCanauxStandard } = require('../utils/canauxStandard');

const norm = (s) => String(s || '').toUpperCase().replace(/[^A-Z0-9]/g, '');

// Partie fixe d'un modèle, normalisée (ex. « {AA}IST-O2/{NNNN} » → « ISTO2 »).
const fixeNormalise = (modele) => {
  const c = compilerModele(modele);
  return c ? norm(c.fixe) : '';
};

// Deux écoles ne doivent pas avoir des parties fixes qui se recouvrent, sinon
// un matricule ne permettrait plus d'identifier l'école.
async function conflitModele(modele, exceptId = null) {
  const fixe = fixeNormalise(modele);
  const r = await pool.query('SELECT id, nom, modele_matricule FROM etablissements WHERE modele_matricule IS NOT NULL');
  for (const e of r.rows) {
    if (exceptId && String(e.id) === String(exceptId)) continue;
    const autre = fixeNormalise(e.modele_matricule);
    if (autre && (autre === fixe || autre.includes(fixe) || fixe.includes(autre))) {
      return `La partie fixe du modèle chevauche celle de « ${e.nom} » (${e.modele_matricule}).`;
    }
  }
  return null;
}

async function codeLibre(base) {
  let code = base;
  for (let i = 2; i < 50; i += 1) {
    const r = await pool.query('SELECT 1 FROM etablissements WHERE UPPER(code) = UPPER($1)', [code]);
    if (r.rows.length === 0) return code;
    code = `${base}${i}`;
  }
  throw new Error('Impossible de générer un code libre.');
}

// Crée un Super Admin pour l'école (users + membres + administrateurs).
async function creerSuperAdmin(etabId, a) {
  const email = String(a.email || '').trim().toLowerCase();
  const dejaPris = await pool.query('SELECT 1 FROM users WHERE email = $1', [email]);
  if (dejaPris.rows.length) {
    const e = new Error('Cet email est déjà utilisé par un autre compte.');
    e.status = 409;
    throw e;
  }
  const cnt = await pool.query("SELECT COUNT(*)::int AS c FROM users WHERE role = 'admin' AND etablissement_id = $1", [etabId]);
  let num = cnt.rows[0].c + 1;
  let matricule;
  for (let i = 0; i < 200; i += 1, num += 1) {
    matricule = `ADM-${new Date().getFullYear()}-${String(num).padStart(3, '0')}`;
    const p = await pool.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
    if (!p.rows.length) break;
  }
  const hash = await bcrypt.hash(a.motDePasse, 10);
  const nom = String(a.nom).trim().toUpperCase();
  const prenoms = String(a.prenoms || '').trim();
  const tel = a.tel ? String(a.tel).trim() : null;
  const u = await pool.query(
    `INSERT INTO users (matricule, nom, prenoms, email, tel, mot_de_passe, role, admin_sub_role, statut, etablissement_id)
     VALUES ($1, $2, $3, $4, $5, $6, 'admin', 'super_admin', 'actif', $7)
     RETURNING id, matricule, nom, prenoms, email`,
    [matricule, nom, prenoms, email, tel, hash, etabId]
  );
  const user = u.rows[0];
  const permissions = JSON.stringify({ domaine: 'Tous' });
  try {
    await pool.query(
      `INSERT INTO membres (user_id, permissions) VALUES ($1, $2)
       ON CONFLICT (user_id) DO UPDATE SET permissions = EXCLUDED.permissions`,
      [user.id, permissions]
    );
    await pool.query('UPDATE membres SET etablissement_id = $1 WHERE user_id = $2', [etabId, user.id]);
  } catch (e) { console.warn('[plateforme] membres :', e.message); }
  try {
    await pool.query(
      `INSERT INTO administrateurs (user_id, nom, prenoms, email, tel, admin_sub_role, permissions, statut)
       VALUES ($1, $2, $3, $4, $5, 'super_admin', $6, 'actif')
       ON CONFLICT (user_id) DO NOTHING`,
      [user.id, nom, prenoms, email, tel, permissions]
    );
    await pool.query('UPDATE administrateurs SET etablissement_id = $1 WHERE user_id = $2', [etabId, user.id]);
  } catch (e) { console.warn('[plateforme] administrateurs :', e.message); }
  return user;
}

function validerAdmin(a) {
  if (!a || !a.nom || !a.email || !a.motDePasse) return 'Le Super Admin doit avoir un nom, un email et un mot de passe.';
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(String(a.email).trim())) return 'Email du Super Admin invalide.';
  if (String(a.motDePasse).length < 8) return 'Le mot de passe du Super Admin doit contenir au moins 8 caractères.';
  return null;
}

// GET /api/plateforme/etablissements
const listerEtablissements = async (req, res) => {
  try {
    const r = await pool.query(
      `SELECT e.id, e.nom, e.sigle, e.ville, e.campus, e.type, e.code, e.modele_matricule,
              COALESCE(e.actif, true) AS actif,
              COALESCE(e.inscription_ouverte, false) AS inscription_ouverte,
              COALESCE(e.inscription_validation, true) AS inscription_validation,
              (SELECT COUNT(*)::int FROM etudiants x WHERE x.etablissement_id = e.id) AS nb_etudiants,
              (SELECT COUNT(*)::int FROM users u WHERE u.etablissement_id = e.id AND u.role = 'professeur') AS nb_professeurs,
              (SELECT COUNT(*)::int FROM users u WHERE u.etablissement_id = e.id AND u.role = 'admin') AS nb_admins
       FROM etablissements e ORDER BY e.id`
    );
    res.json({ success: true, data: r.rows });
  } catch (err) {
    console.error('[plateforme] liste', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// POST /api/plateforme/etablissements
// body: { nom, sigle, ville, campus, type, code?, modele_matricule,
//         admin: { nom, prenoms, email, tel, motDePasse } }
const creerEtablissement = async (req, res) => {
  let etabId = null;
  try {
    const { nom, sigle, ville, campus, type, modele_matricule, admin } = req.body || {};
    if (!nom?.trim() || !sigle?.trim()) {
      return res.status(400).json({ success: false, message: "Le nom et le sigle de l'établissement sont obligatoires." });
    }
    const m = modeleValide(modele_matricule);
    if (!m.ok) return res.status(400).json({ success: false, message: m.message });
    const conflit = await conflitModele(modele_matricule);
    if (conflit) return res.status(409).json({ success: false, message: conflit });
    const errAdmin = validerAdmin(admin);
    if (errAdmin) return res.status(400).json({ success: false, message: errAdmin });

    let code = String(req.body.code || '').trim().toUpperCase();
    if (code) {
      if (!/^[A-Z0-9]{4,20}$/.test(code)) {
        return res.status(400).json({ success: false, message: 'Le code doit contenir 4 à 20 lettres/chiffres, sans espace.' });
      }
      const ex = await pool.query('SELECT 1 FROM etablissements WHERE UPPER(code) = $1', [code]);
      if (ex.rows.length) return res.status(409).json({ success: false, message: 'Ce code est déjà utilisé.' });
    } else {
      code = await codeLibre(`${norm(sigle)}${new Date().getFullYear()}`);
    }
    const exEmail = await pool.query('SELECT 1 FROM users WHERE email = $1', [String(admin.email).trim().toLowerCase()]);
    if (exEmail.rows.length) {
      return res.status(409).json({ success: false, message: 'Cet email est déjà utilisé par un autre compte.' });
    }

    const ins = await pool.query(
      `INSERT INTO etablissements (nom, sigle, ville, campus, type, code, modele_matricule, actif, inscription_ouverte, inscription_validation)
       VALUES ($1, $2, $3, $4, $5, $6, $7, true, false, true) RETURNING id, nom, sigle, ville, campus, type, code, modele_matricule`,
      [nom.trim(), sigle.trim().toUpperCase(), ville?.trim() || '', campus?.trim() || '', type?.trim() || 'superieur', code, String(modele_matricule).trim()]
    );
    const etab = ins.rows[0];
    etabId = etab.id;

    const canaux = await ensureCanauxStandard(etabId);
    const superAdmin = await creerSuperAdmin(etabId, admin);

    res.status(201).json({
      success: true,
      message: `Établissement « ${etab.nom} » créé.`,
      data: { etablissement: etab, canaux, super_admin: { id: superAdmin.id, matricule: superAdmin.matricule, email: superAdmin.email } },
    });
  } catch (err) {
    console.error('[plateforme] création', err);
    // Annulation « à la main » : on ne laisse pas une école à moitié créée.
    if (etabId) {
      try {
        await pool.query('DELETE FROM users WHERE etablissement_id = $1', [etabId]);
        await pool.query('DELETE FROM canaux WHERE etablissement_id = $1', [etabId]);
        await pool.query('DELETE FROM etablissements WHERE id = $1', [etabId]);
      } catch (e2) { console.error('[plateforme] annulation impossible', e2.message); }
    }
    res.status(err.status || 500).json({ success: false, message: err.status ? err.message : 'Erreur serveur pendant la création.' });
  }
};

// PATCH /api/plateforme/etablissements/:id
const modifierEtablissement = async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    if (!Number.isInteger(id)) return res.status(400).json({ success: false, message: 'Identifiant invalide.' });
    const b = req.body || {};
    const sets = [];
    const params = [];
    const ajoute = (col, val) => { params.push(val); sets.push(`${col} = $${params.length}`); };

    for (const col of ['nom', 'sigle', 'ville', 'campus', 'type']) {
      if (b[col] !== undefined) ajoute(col, String(b[col]).trim());
    }
    if (b.code !== undefined) {
      const code = String(b.code).trim().toUpperCase();
      if (!/^[A-Z0-9]{4,20}$/.test(code)) return res.status(400).json({ success: false, message: 'Code invalide (4 à 20 lettres/chiffres).' });
      const ex = await pool.query('SELECT 1 FROM etablissements WHERE UPPER(code) = $1 AND id <> $2', [code, id]);
      if (ex.rows.length) return res.status(409).json({ success: false, message: 'Ce code est déjà utilisé.' });
      ajoute('code', code);
    }
    if (b.modele_matricule !== undefined) {
      const m = modeleValide(b.modele_matricule);
      if (!m.ok) return res.status(400).json({ success: false, message: m.message });
      const conflit = await conflitModele(b.modele_matricule, id);
      if (conflit) return res.status(409).json({ success: false, message: conflit });
      ajoute('modele_matricule', String(b.modele_matricule).trim());
    }
    for (const col of ['actif', 'inscription_ouverte', 'inscription_validation']) {
      if (b[col] !== undefined) ajoute(col, b[col] === true || b[col] === 'true');
    }
    if (!sets.length) return res.status(400).json({ success: false, message: 'Rien à modifier.' });
    params.push(id);
    const r = await pool.query(
      `UPDATE etablissements SET ${sets.join(', ')} WHERE id = $${params.length}
       RETURNING id, nom, sigle, ville, campus, type, code, modele_matricule, actif, inscription_ouverte, inscription_validation`,
      params
    );
    if (!r.rows[0]) return res.status(404).json({ success: false, message: 'Établissement introuvable.' });
    res.json({ success: true, data: r.rows[0] });
  } catch (err) {
    console.error('[plateforme] modification', err);
    res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// POST /api/plateforme/etablissements/:id/super-admin
// Ajoute un Super Admin (premier compte perdu, remplacement…).
const ajouterSuperAdmin = async (req, res) => {
  try {
    const id = parseInt(req.params.id, 10);
    const e = await pool.query('SELECT id FROM etablissements WHERE id = $1', [id]);
    if (!e.rows[0]) return res.status(404).json({ success: false, message: 'Établissement introuvable.' });
    const errAdmin = validerAdmin(req.body);
    if (errAdmin) return res.status(400).json({ success: false, message: errAdmin });
    const user = await creerSuperAdmin(id, req.body);
    res.status(201).json({ success: true, data: { id: user.id, matricule: user.matricule, email: user.email } });
  } catch (err) {
    console.error('[plateforme] super-admin', err);
    res.status(err.status || 500).json({ success: false, message: err.status ? err.message : 'Erreur serveur.' });
  }
};

module.exports = { listerEtablissements, creerEtablissement, modifierEtablissement, ajouterSuperAdmin };
