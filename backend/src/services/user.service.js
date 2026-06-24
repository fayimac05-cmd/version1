const pool = require('../config/db');

async function getUserById(id) {
  const r = await pool.query(
    `SELECT u.id, u.nom, u.prenoms, u.role, u.matricule, u.filiere_id, u.etablissement_id,
            f.nom AS filiere
     FROM users u
     LEFT JOIN filieres f ON f.id = u.filiere_id
     WHERE u.id = $1`,
    [id]
  );
  return r.rows[0] || null;
}

async function getUsersByIds(ids) {
  if (!ids || ids.length === 0) return {};
  const unique = [...new Set(ids)];
  const r = await pool.query(
    'SELECT id, nom, prenoms, role, matricule FROM users WHERE id = ANY($1::uuid[])',
    [unique]
  );
  return Object.fromEntries(r.rows.map((u) => [u.id, u]));
}

function formatAuteur(user) {
  if (!user) return { nom: 'Utilisateur', initiales: '??' };
  const initiales = `${(user.prenoms || '')[0] || ''}${(user.nom || '')[0] || ''}`.toUpperCase();
  return {
    id: user.id,
    nom: `${user.prenoms || ''} ${user.nom || ''}`.trim(),
    initiales: initiales || '??',
    role: user.role,
    matricule: user.matricule,
  };
}

async function enrichMessages(messages) {
  const auteurIds = messages.map((m) => m.auteur_id);
  const users = await getUsersByIds(auteurIds);
  return messages.map((m) => ({
    ...m,
    auteur: formatAuteur(users[m.auteur_id]),
  }));
}

module.exports = { getUserById, getUsersByIds, formatAuteur, enrichMessages };
