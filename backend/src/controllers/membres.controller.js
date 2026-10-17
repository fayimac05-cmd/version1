const pool = require('../config/db');
const supabase = require('../config/supabase');
const bcrypt = require('bcryptjs');

// ── Multi-établissement ─────────────────────────────────────────────────────
// req.etablissementId vient du jeton ; s'il est absent (anciens jetons), pas de filtre.
// Un administrateur appartient à un établissement (users / administrateurs / membres).
const membreDeMonEtab = async (id, etabId) => {
  if (!etabId) return true;
  const r = await pool.query(
    `SELECT 1 FROM users WHERE id = $1 AND etablissement_id = $2`, [id, etabId]
  );
  return r.rows.length > 0;
};

// ── GET /api/membres — Récupérer tous les administrateurs et membres ────────
const getAllMembres = async (req, res) => {
  try {
    let membres = [];
    try {
      const pl = [];
      let filtreEtab = '';
      if (req.etablissementId) {
        pl.push(req.etablissementId);
        filtreEtab = ` AND u.etablissement_id = $${pl.length}`;
      }
      const r = await pool.query(
        `SELECT u.id, u.nom, u.prenoms, u.email, u.tel, u.role, u.admin_sub_role, u.statut,
                COALESCE(m.permissions, '{}'::jsonb) AS permissions
         FROM users u
         LEFT JOIN membres m ON u.id = m.user_id
         WHERE (u.role = 'admin' OR u.role = 'admi' OR u.role = 'administrator')${filtreEtab}
         ORDER BY u.nom`,
        pl
      );
      membres = r.rows;
    } catch (dbErr) {
      console.warn('Direct PG failed in getAllMembres, fallback to Supabase SDK:', dbErr.message);
      if (supabase && typeof supabase.from === 'function') {
        let q = supabase
          .from('users')
          .select('id, nom, prenoms, email, tel, role, admin_sub_role, statut, permissions')
          .or('role.eq.admin,role.eq.admi');
        if (req.etablissementId) q = q.eq('etablissement_id', req.etablissementId);
        const { data, error } = await q;
        if (!error && data) membres = data;
      }
    }

    return res.status(200).json({
      success: true,
      data: membres.map((m) => {
        const permissionsParsed = typeof m.permissions === 'string' ? JSON.parse(m.permissions) : (m.permissions || {});
        return {
          id: m.id,
          nom: m.nom || '',
          prenoms: m.prenoms || '',
          email: m.email || '',
          tel: m.tel || '',
          numero: m.tel || '',
          role: m.admin_sub_role || m.role || 'super_admin',
          admin_sub_role: m.admin_sub_role || 'super_admin',
          domaine: m.domaine || permissionsParsed.domaine || 'Tous',
          droits: permissionsParsed,
          actif: m.statut !== 'suspendu' && m.statut !== 'renvoye',
          dateCreation: m.created_at ? new Date(m.created_at).toLocaleDateString('fr-FR') : '01/01/2026',
        };
      }),
    });
  } catch (err) {
    console.error('getAllMembres error:', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur lors de la récupération.' });
  }
};

// ── POST /api/membres — Inscrire un nouvel administrateur en Base de Données ──
const createMembre = async (req, res) => {
  let client;
  try {
    const { nom, prenoms, email, tel, telephone, numero, motDePasse, role, admin_sub_role, domaine, permissions } = req.body;

    if (!nom || !email || !motDePasse) {
      return res.status(400).json({ success: false, message: 'Nom, Email et Mot de passe sont requis.' });
    }

    const telFinal = tel || telephone || numero || null;
    const pass = motDePasse;
    const hashedPassword = await bcrypt.hash(pass, 10);
    const subRole = admin_sub_role || role || 'scolarite';
    const domaineFinal = domaine || 'Tous';
    const permissionsObj = { ...(permissions || {}), domaine: domaineFinal };

    const etabId = req.etablissementId || null;
    let createdUser = null;

    try {
      client = await pool.connect();
      await client.query('BEGIN');

      // Vérifier si l'email existe déjà
      const checkEmail = await client.query('SELECT id FROM users WHERE email = $1', [email.trim().toLowerCase()]);
      if (checkEmail.rows.length > 0) {
        await client.query('ROLLBACK');
        return res.status(409).json({ success: false, message: 'Cet email est déjà utilisé par un autre compte.' });
      }

      // Générer matricule admin unique (la clé users.matricule est globale : on
      // incrémente jusqu'à trouver un numéro libre, quel que soit l'établissement)
      const pc = [];
      let filtreCount = '';
      if (etabId) { pc.push(etabId); filtreCount = ` AND etablissement_id = $${pc.length}`; }
      const countRes = await client.query(`SELECT COUNT(*)::int AS c FROM users WHERE role = 'admin'${filtreCount}`, pc);
      let numAdm = countRes.rows[0].c + 1;
      let matricule;
      for (let i = 0; i < 200; i += 1, numAdm += 1) {
        matricule = `ADM-${new Date().getFullYear()}-${numAdm.toString().padStart(3, '0')}`;
        const dejaPris = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
        if (dejaPris.rows.length === 0) break;
      }

      // 1. Insertion dans la table users
      const userRes = etabId
        ? await client.query(
            `INSERT INTO users (matricule, nom, prenoms, email, tel, mot_de_passe, role, admin_sub_role, statut, etablissement_id)
             VALUES ($1, $2, $3, $4, $5, $6, 'admin', $7, 'actif', $8)
             RETURNING id, matricule, nom, prenoms, email, tel, role, admin_sub_role`,
            [matricule, nom.trim().toUpperCase(), prenoms.trim(), email.trim().toLowerCase(), telFinal, hashedPassword, subRole, etabId]
          )
        : await client.query(
            `INSERT INTO users (matricule, nom, prenoms, email, tel, mot_de_passe, role, admin_sub_role, statut)
             VALUES ($1, $2, $3, $4, $5, $6, 'admin', $7, 'actif')
             RETURNING id, matricule, nom, prenoms, email, tel, role, admin_sub_role`,
            [matricule, nom.trim().toUpperCase(), prenoms.trim(), email.trim().toLowerCase(), telFinal, hashedPassword, subRole]
          );
      createdUser = userRes.rows[0];

      // 2. Insertion dans la table membres / permissions
      await client.query(
        `INSERT INTO membres (user_id, permissions)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE SET permissions = EXCLUDED.permissions`,
        [createdUser.id, JSON.stringify(permissionsObj)]
      );
      if (etabId) {
        // etablissement_id existe sur membres / administrateurs (migration phase 1)
        try { await client.query('UPDATE membres SET etablissement_id = $1 WHERE user_id = $2', [etabId, createdUser.id]); } catch (_) {}
      }

      // 3. Insertion dans la table administrateurs (sans colonne 'role' qui n'existe pas)
      try {
        await client.query(
          `INSERT INTO administrateurs (user_id, nom, prenoms, email, tel, admin_sub_role, permissions, statut)
           VALUES ($1, $2, $3, $4, $5, $6, $7, 'actif')
           ON CONFLICT (user_id) DO UPDATE SET
             nom = EXCLUDED.nom, prenoms = EXCLUDED.prenoms,
             email = EXCLUDED.email, tel = EXCLUDED.tel,
             admin_sub_role = EXCLUDED.admin_sub_role,
             permissions = EXCLUDED.permissions`,
          [createdUser.id, nom.trim().toUpperCase(), prenoms?.trim() || '', email.trim().toLowerCase(), telFinal, subRole, JSON.stringify(permissionsObj)]
        );
        if (etabId) {
          try { await client.query('UPDATE administrateurs SET etablissement_id = $1 WHERE user_id = $2', [etabId, createdUser.id]); } catch (_) {}
        }
      } catch (admErr) {
        console.warn('[createMembre] Insertion dans administrateurs échouée:', admErr.message);
      }

      await client.query('COMMIT');
    } catch (dbErr) {
      if (client) try { await client.query('ROLLBACK'); } catch (_) { }
      console.warn('Direct PG failed in createMembre, fallback to Supabase SDK:', dbErr.message);

      if (supabase && typeof supabase.from === 'function') {
        const { data: userSup, error: errSup } = await supabase.from('users').insert([{
          nom: nom.trim().toUpperCase(),
          prenoms: prenoms?.trim() || '',
          email: email.trim().toLowerCase(),
          tel: telFinal,
          mot_de_passe: hashedPassword,
          role: 'admin',
          admin_sub_role: subRole,
          statut: 'actif',
          ...(etabId ? { etablissement_id: etabId } : {}),
        }]).select().single();

        if (errSup) return res.status(500).json({ success: false, message: errSup.message });
        createdUser = userSup;

        // Insertion dans membres
        await supabase.from('membres').insert([{
          user_id: createdUser.id,
          permissions: permissionsObj
        }]);

        // Insertion dans administrateurs via Supabase SDK (sans colonne 'role')
        const { error: admSupErr } = await supabase.from('administrateurs').upsert([{
          user_id: createdUser.id,
          nom: nom.trim().toUpperCase(),
          prenoms: prenoms?.trim() || '',
          email: email.trim().toLowerCase(),
          tel: telFinal,
          admin_sub_role: subRole,
          permissions: permissionsObj,
          statut: 'actif',
          ...(etabId ? { etablissement_id: etabId } : {}),
        }], { onConflict: 'user_id' });

        if (admSupErr) {
          console.warn('[createMembre] Supabase administrateurs upsert error:', admSupErr.message);
        }
      }
    } finally {
      if (client) client.release();
    }

    return res.status(201).json({
      success: true,
      message: 'Administrateur créé avec succès en base de données.',
      data: {
        id: createdUser.id,
        nom: createdUser.nom,
        prenoms: createdUser.prenoms,
        email: createdUser.email,
        role: createdUser.admin_sub_role || subRole,
        admin_sub_role: subRole,
        domaine: domaineFinal,
        droits: permissionsObj,
        actif: true,
      },
    });
  } catch (err) {
    console.error('createMembre error:', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur lors de la création.' });
  }
};

// ── PATCH /api/membres/:id/permissions — Modifier les droits ─────────────────
const updatePermissions = async (req, res) => {
  try {
    const { id } = req.params;
    const { permissions, role } = req.body;

    if (!(await membreDeMonEtab(id, req.etablissementId))) {
      return res.status(404).json({ success: false, message: 'Membre introuvable.' });
    }

    try {
      await pool.query(
        `INSERT INTO membres (user_id, permissions)
         VALUES ($1, $2)
         ON CONFLICT (user_id) DO UPDATE SET permissions = $2`,
        [id, JSON.stringify(permissions || {})]
      );

      if (role) {
        await pool.query('UPDATE users SET admin_sub_role = $1 WHERE id = $2', [role, id]);
      }
    } catch (dbErr) {
      if (supabase && typeof supabase.from === 'function') {
        await supabase.from('membres').upsert({ user_id: id, permissions: permissions || {} });
        if (role) await supabase.from('users').update({ admin_sub_role: role }).eq('id', id);
      }
    }

    return res.status(200).json({ success: true, message: 'Permissions mises à jour en base de données.' });
  } catch (err) {
    console.error('updatePermissions error:', err);
    return res.status(500).json({ success: false, message: 'Erreur serveur.' });
  }
};

// ── DELETE /api/membres/:id — Supprimer un administrateur ────────────────────
const deleteMembre = async (req, res) => {
  try {
    const { id } = req.params;
    if (!(await membreDeMonEtab(id, req.etablissementId))) {
      return res.status(404).json({ success: false, message: 'Membre introuvable.' });
    }
    try {
      await pool.query('DELETE FROM users WHERE id = $1', [id]);
    } catch (dbErr) {
      if (supabase && typeof supabase.from === 'function') {
        await supabase.from('users').delete().eq('id', id);
      }
    }
    return res.status(200).json({ success: true, message: 'Membre supprimé de la base de données.' });
  } catch (err) {
    console.error('deleteMembre error:', err);
    return res.status(500).json({ success: false, message: 'Erreur lors de la suppression.' });
  }
};

module.exports = {
  getAllMembres,
  createMembre,
  updatePermissions,
  deleteMembre,
};