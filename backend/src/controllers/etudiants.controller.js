const pool = require('../config/db');
const { ensureFilieres } = require('../utils/filieres');

const domaineFromFiliere = (filiere) => {
  const f = (filiere || '').toLowerCase();
  if (f.includes('marketing') || f.includes('gestion') || f.includes('finance') || f.includes('comptab')) {
    return 'Sciences de Gestion';
  }
  return 'Sciences & Technologies';
};

const generateMatricule = async (client) => {
  const annee = new Date().getFullYear().toString().slice(2);
  const countRes = await client.query(
    "SELECT COUNT(*)::int AS c FROM users WHERE role = 'etudiant'"
  );
  let num = 1900 + countRes.rows[0].c + 1;
  let matricule = `${annee}IST-O2/${num}`;
  let exists = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
  while (exists.rows.length > 0) {
    num += 1;
    matricule = `${annee}IST-O2/${num}`;
    exists = await client.query('SELECT 1 FROM users WHERE matricule = $1', [matricule]);
  }
  return matricule;
};

const mapRowToEtudiant = (row) => ({
  id: row.etudiant_id,
  userId: row.user_id,
  matricule: row.matricule,
  nom: row.nom,
  prenoms: row.prenoms,
  email: row.email || '',
  telephone: row.tel || '',
  filiere: row.filiere_nom || '',
  filiereId: row.filiere_id,
  domaine: row.domaine || domaineFromFiliere(row.filiere_nom),
  niveau: row.niveau || '',
  dateNaissance: row.date_naissance || '',
  nationalite: row.nationalite || 'Burkinabè',
  adresse: row.adresse || '',
  nomParent: row.nom_parent || '',
  telParent: row.tel_parent || '',
  emailParent: row.email_parent || '',
  statut: row.statut || 'actif',
  role: row.etudiant_role || 'etudiant',
  filiereRole: row.filiere_role || null,
  premiereFois: row.premierefois ?? true,
});

const listEtudiants = async (req, res) => {
  try {
    const result = await pool.query(`
      SELECT
        e.id AS etudiant_id,
        e.user_id,
        COALESCE(e.matricule, u.matricule) AS matricule,
        COALESCE(e.nom, u.nom) AS nom,
        COALESCE(e.prenoms, u.prenoms) AS prenoms,
        COALESCE(e.email, u.email) AS email,
        COALESCE(e.tel, u.tel) AS tel,
        COALESCE(e.statut, u.statut) AS statut,
        COALESCE(e.domaine, u.domaine) AS domaine,
        COALESCE(e.niveau, u.niveau) AS niveau,
        COALESCE(e.date_naissance, u.date_naissance) AS date_naissance,
        COALESCE(e.nationalite, u.nationalite) AS nationalite,
        COALESCE(e.adresse, u.adresse) AS adresse,
        COALESCE(e.nom_parent, u.nom_parent) AS nom_parent,
        COALESCE(e.tel_parent, u.tel_parent) AS tel_parent,
        COALESCE(e.email_parent, u.email_parent) AS email_parent,
        u.etudiant_role,
        u.filiere_role,
        e.filiere_id,
        e.premierefois,
        COALESCE(e.filiere_nom, f.nom) AS filiere_nom
      FROM etudiants e
      INNER JOIN users u ON u.id = e.user_id
      LEFT JOIN filieres f ON f.id = e.filiere_id
      WHERE u.role = 'etudiant'
      ORDER BY COALESCE(e.nom, u.nom), COALESCE(e.prenoms, u.prenoms)
    `);
    return res.status(200).json(result.rows.map(mapRowToEtudiant));
  } catch (err) {
    console.error('[listEtudiants]', err);
    return res.status(500).json({ message: 'Erreur lors du chargement des étudiants.' });
  }
};

const inscrireEtudiant = async (req, res) => {
  const client = await pool.connect();
  try {
    const {
      nom,
      prenoms,
      email,
      telephone,
      filiere,
      niveau,
      domaine,
      dateNaissance,
      adresse,
      nomParent,
      telParent,
      emailParent,
      nationalite,
      matricule: matriculeBody,
    } = req.body;

    if (!nom?.trim() || !prenoms?.trim()) {
      return res.status(400).json({ message: 'Nom et prénom requis.' });
    }
    if (!filiere?.trim()) {
      return res.status(400).json({ message: 'Filière requise.' });
    }

    await client.query('BEGIN');
    await ensureFilieres(client);

    const filiereRes = await client.query('SELECT id FROM filieres WHERE nom = $1', [filiere.trim()]);
    const filiereId = filiereRes.rows[0]?.id || null;

    const matricule = (matriculeBody?.trim().toUpperCase()) || (await generateMatricule(client));
    const emailFinal = email?.trim() || `${matricule.split('/')[1]}@ist.bf`;
    const domaineFinal = domaine?.trim() || domaineFromFiliere(filiere);

    const userRes = await client.query(
      `INSERT INTO users (
        matricule, nom, prenoms, email, tel, role, statut, mot_de_passe,
        domaine, niveau, date_naissance, nationalite, adresse,
        nom_parent, tel_parent, email_parent, etudiant_role, filiere_nom
      ) VALUES (
        $1, $2, $3, $4, $5, 'etudiant', 'actif', NULL,
        $6, $7, $8, $9, $10,
        $11, $12, $13, 'etudiant', $14
      )
      RETURNING id`,
      [
        matricule,
        nom.trim().toUpperCase(),
        prenoms.trim(),
        emailFinal,
        telephone?.trim() || null,
        domaineFinal,
        niveau?.trim() || null,
        dateNaissance?.trim() || null,
        nationalite?.trim() || 'Burkinabè',
        adresse?.trim() || null,
        nomParent?.trim() || null,
        telParent?.trim() || null,
        emailParent?.trim() || null,
        filiere.trim(),
      ]
    );

    const userId = userRes.rows[0].id;

    const etuRes = await client.query(
      `INSERT INTO etudiants (
        user_id, filiere_id, premierefois,
        matricule, nom, prenoms, email, tel,
        filiere_nom, domaine, niveau, date_naissance, nationalite,
        adresse, nom_parent, tel_parent, email_parent, statut
      ) VALUES (
        $1, $2, true,
        $3, $4, $5, $6, $7,
        $8, $9, $10, $11, $12,
        $13, $14, $15, $16, 'actif'
      )
      RETURNING id`,
      [
        userId,
        filiereId,
        matricule,
        nom.trim().toUpperCase(),
        prenoms.trim(),
        emailFinal,
        telephone?.trim() || null,
        filiere.trim(),
        domaineFinal,
        niveau?.trim() || null,
        dateNaissance?.trim() || null,
        nationalite?.trim() || 'Burkinabè',
        adresse?.trim() || null,
        nomParent?.trim() || null,
        telParent?.trim() || null,
        emailParent?.trim() || null,
      ]
    );

    await client.query('COMMIT');

    return res.status(201).json({
      success: true,
      matricule,
      etudiant: {
        id: etuRes.rows[0].id,
        userId,
        matricule,
        nom: nom.trim().toUpperCase(),
        prenoms: prenoms.trim(),
        email: emailFinal,
        telephone: telephone?.trim() || '',
        filiere,
        filiereId,
        domaine: domaineFinal,
        niveau: niveau?.trim() || '',
        dateNaissance: dateNaissance?.trim() || '',
        nationalite: nationalite?.trim() || 'Burkinabè',
        adresse: adresse?.trim() || '',
        nomParent: nomParent?.trim() || '',
        telParent: telParent?.trim() || '',
        emailParent: emailParent?.trim() || '',
        statut: 'actif',
        role: 'etudiant',
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('[inscrireEtudiant]', err);
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Matricule ou email déjà utilisé.' });
    }
    return res.status(500).json({ message: err.message || 'Erreur lors de l\'inscription.' });
  } finally {
    client.release();
  }
};

module.exports = { listEtudiants, inscrireEtudiant };
