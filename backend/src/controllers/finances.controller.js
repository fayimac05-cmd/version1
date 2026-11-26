// backend/src/controllers/finances.controller.js
// Module FINANCES : grille tarifaire, encaissement, impayés, relances,
// blocage des notes, dépenses, rapport.
//
// PAIEMENT EN LIGNE : tout passe par getProvider() (services/paiement.service).
// Le jour où tu obtiens l'API Orange Money, tu ne modifies QUE ce service
// (méthodes initier / confirmer, et éventuellement traiterWebhook) : rien ici.

const pool = require('../config/db');
const { getProvider, OPERATEURS } = require('../services/paiement.service');
const { envoyerNotificationAuto } = require('./notifications.controller');
const { envoyerSMS } = require('../services/sms.service');
const { grilleApplicable, calculerSituation, numeroRecu, dateISO, enLettres } = require('../services/finances.calcul');

const LABELS_MODE = {
  especes: 'Espèces', virement: 'Virement bancaire', cheque: 'Chèque',
  orange_money: 'Orange Money', moov_money: 'Moov Money', wave: 'Wave', mtn_momo: 'MTN MoMo',
};
const MODES_MANUELS = ['especes', 'virement', 'cheque', 'orange_money', 'moov_money', 'wave', 'mtn_momo'];
const CATEGORIES_DEPENSES = ['salaires', 'loyer', 'fournitures', 'maintenance', 'eau_electricite', 'transport', 'communication', 'autre'];

// La couche DB (Supabase execute_sql) n'accepte pas BEGIN/COMMIT/ROLLBACK :
// on exécute les requêtes directement et on nettoie à la main en cas d'échec.
async function connecter() {
  return {
    query: (sql, params) => (/^\s*(BEGIN|COMMIT|ROLLBACK)\s*;?\s*$/i.test(sql) ? Promise.resolve({ rows: [] }) : pool.query(sql, params)),
    release: () => {},
  };
}

const wrap = (nom, fn) => async (req, res) => {
  try { await fn(req, res); }
  catch (e) {
    console.error(`[finances.${nom}]`, e);
    res.status(500).json({ success: false, message: 'Erreur serveur (finances).' });
  }
};
const nombre = (v) => Number(v) || 0;

// Rôles : l'administration voit tout ; le personnel de caisse encaisse et clôture sa caisse.
const ROLES_ADMIN = ['admin', 'direction'];
const ROLES_CAISSE = [...ROLES_ADMIN, 'caissier', 'scolarite', 'comptable', 'comptabilite'];
const estAdmin = (req) => ROLES_ADMIN.includes(req.user?.role);
const jourValide = (d) => (/^\d{4}-\d{2}-\d{2}$/.test(String(d || '')) ? String(d) : new Date().toISOString().slice(0, 10));
const qui = (req) => String(req.user?.email || req.user?.nom || req.user?.id || '');

// ── Année académique ────────────────────────────────────────────────────────
function anneeParDefaut() {
  const d = new Date(); const y = d.getFullYear();
  return d.getMonth() >= 8 ? `${y}-${y + 1}` : `${y - 1}-${y}`;
}
async function anneeCourante(req) {
  if (req.query?.annee) return String(req.query.annee);
  const r = await pool.query(
    `SELECT annee_academique FROM finance_grilles
     WHERE etablissement_id = $1 AND actif = TRUE ORDER BY annee_academique DESC LIMIT 1`,
    [req.etablissementId]);
  return r.rows[0]?.annee_academique || anneeParDefaut();
}
function fenetreAnnee(annee) {
  const m = String(annee).match(/(\d{4})\D+(\d{4})/);
  const y1 = m ? Number(m[1]) : new Date().getFullYear();
  const y2 = m ? Number(m[2]) : y1 + 1;
  return { du: `${y1}-09-01`, au: `${y2}-08-31` };
}

// ── Chargements groupés ─────────────────────────────────────────────────────
async function chargerGrilles(etab, annee) {
  const g = await pool.query(
    `SELECT * FROM finance_grilles WHERE etablissement_id = $1 AND annee_academique = $2
     ORDER BY type, domaine NULLS FIRST, niveau NULLS FIRST, id`, [etab, annee]);
  if (!g.rows.length) return [];
  const t = await pool.query(
    `SELECT * FROM finance_tranches WHERE grille_id = ANY($1::int[]) ORDER BY grille_id, numero`,
    [g.rows.map((x) => x.id)]);
  return g.rows.map((x) => ({ ...x, montant_total: nombre(x.montant_total),
    tranches: t.rows.filter((y) => y.grille_id === x.id).map((y) => ({ ...y, montant: nombre(y.montant), echeance: dateISO(y.echeance) })) }));
}

const SQL_ETUDIANTS = `
  SELECT e.id, e.user_id, e.matricule, e.nom, e.prenoms, e.filiere_id, e.filiere_nom,
         e.niveau, e.tel_parent, f.domaine
  FROM etudiants e LEFT JOIN filieres f ON f.id = e.filiere_id`;

async function totauxParEtudiant(etab, annee) {
  const [rem, ver, blo, rel] = await Promise.all([
    pool.query(`SELECT etudiant_id::text AS k, SUM(montant) AS s FROM finance_remises
                WHERE etablissement_id = $1 AND annee_academique = $2 GROUP BY etudiant_id`, [etab, annee]),
    pool.query(`SELECT etudiant_id::text AS k, SUM(montant) AS s FROM finance_versements
                WHERE etablissement_id = $1 AND annee_academique = $2 AND statut = 'reussi' GROUP BY etudiant_id`, [etab, annee]),
    pool.query(`SELECT etudiant_id::text AS k, motif FROM finance_blocages WHERE etablissement_id = $1 AND bloque = TRUE`, [etab]),
    pool.query(`SELECT etudiant_id::text AS k, MAX(created_at) AS d FROM finance_relances
                WHERE etablissement_id = $1 GROUP BY etudiant_id`, [etab]),
  ]);
  const m = (rows, f) => Object.fromEntries(rows.map((r) => [r.k, f(r)]));
  return { remises: m(rem.rows, (r) => nombre(r.s)), paye: m(ver.rows, (r) => nombre(r.s)),
    blocages: m(blo.rows, (r) => r.motif || ''), relances: m(rel.rows, (r) => r.d) };
}

function situationPour(etu, grilles, tot) {
  const k = String(etu.id);
  const app = grilles.filter((g) => grilleApplicable(g, etu));
  const s = calculerSituation({ grilles: app, remises: tot.remises[k] || 0, paye: tot.paye[k] || 0 });
  return { ...s, bloque: Object.prototype.hasOwnProperty.call(tot.blocages, k),
    motif_blocage: tot.blocages[k] || null, derniere_relance: tot.relances[k] || null };
}

async function situationEtudiant(etab, etu, annee) {
  const [grilles, tot] = await Promise.all([chargerGrilles(etab, annee), totauxParEtudiant(etab, annee)]);
  return situationPour(etu, grilles, tot);
}

async function trouverEtudiant(etab, id) {
  const r = await pool.query(`${SQL_ETUDIANTS} WHERE e.id = $1 AND e.etablissement_id = $2`, [id, etab]);
  return r.rows[0] || null;
}
async function etudiantDeUser(req) {
  const r = await pool.query(`${SQL_ETUDIANTS} WHERE e.user_id = $1 AND e.etablissement_id = $2`, [req.user.id, req.etablissementId]);
  return r.rows[0] || null;
}
async function parentALEnfant(userId, etudiantId) {
  const r = await pool.query(
    `SELECT 1 FROM parents p JOIN parent_etudiants pe ON pe.parent_id = p.id
     WHERE p.user_id::text = $1 AND pe.etudiant_id = $2`, [String(userId), etudiantId]);
  return r.rows.length > 0;
}
// Étudiant concerné par la requête : l'étudiant lui-même, son parent, ou l'admin.
async function etudiantAutorise(req, etudiantId) {
  const role = req.user.role;
  if (ROLES_CAISSE.includes(role)) return trouverEtudiant(req.etablissementId, etudiantId);
  if (role === 'parent') return (await parentALEnfant(req.user.id, etudiantId)) ? trouverEtudiant(req.etablissementId, etudiantId) : null;
  const moi = await etudiantDeUser(req);
  return moi && String(moi.id) === String(etudiantId) ? moi : null;
}

// ═══ GRILLE (admin) ═════════════════════════════════════════════════════════
const getGrilles = wrap('getGrilles', async (req, res) => {
  const annee = await anneeCourante(req);
  const annees = await pool.query(
    `SELECT DISTINCT annee_academique FROM finance_grilles WHERE etablissement_id = $1 ORDER BY 1 DESC`, [req.etablissementId]);
  res.json({ success: true, annee, annees: annees.rows.map((r) => r.annee_academique),
    data: await chargerGrilles(req.etablissementId, annee) });
});

function validerGrille(b) {
  const montant = nombre(b.montant_total);
  if (!b.libelle || !String(b.libelle).trim()) return 'Le libellé est obligatoire.';
  if (!/^\d{4}\D+\d{4}$/.test(String(b.annee_academique || ''))) return "Année académique invalide (ex. 2026-2027).";
  if (!['inscription', 'scolarite', 'autre'].includes(b.type)) return 'Type invalide.';
  if (!(montant >= 0)) return 'Montant invalide.';
  const tr = Array.isArray(b.tranches) ? b.tranches : [];
  if (tr.length) {
    const somme = tr.reduce((s, t) => s + nombre(t.montant), 0);
    if (tr.some((t) => !(nombre(t.montant) > 0))) return 'Chaque tranche doit avoir un montant positif.';
    if (somme !== montant) return `La somme des tranches (${somme}) doit être égale au montant total (${montant}).`;
  }
  return null;
}

async function ecrireGrille(client, req, id, b) {
  const params = [req.etablissementId, String(b.annee_academique), b.type, String(b.libelle).trim(),
    b.domaine || null, b.filiere_id || null, b.niveau || null, nombre(b.montant_total), b.actif !== false];
  let gid = id;
  if (id) {
    await client.query(
      `UPDATE finance_grilles SET annee_academique=$2, type=$3, libelle=$4, domaine=$5, filiere_id=$6,
              niveau=$7, montant_total=$8, actif=$9 WHERE id=$10 AND etablissement_id=$1`, [...params, id]);
    await client.query('DELETE FROM finance_tranches WHERE grille_id = $1', [id]);
  } else {
    const r = await client.query(
      `INSERT INTO finance_grilles (etablissement_id, annee_academique, type, libelle, domaine, filiere_id, niveau, montant_total, actif)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`, params);
    gid = r.rows[0].id;
  }
  let n = 1;
  try {
    for (const t of (b.tranches || [])) {
      await client.query(
        `INSERT INTO finance_tranches (grille_id, numero, libelle, montant, echeance) VALUES ($1,$2,$3,$4,$5)`,
        [gid, n, t.libelle || `Tranche ${n}`, nombre(t.montant), t.echeance || null]);
      n += 1;
    }
  } catch (e) {
    if (!id) await client.query('DELETE FROM finance_grilles WHERE id = $1', [gid]).catch(() => {});
    throw e;
  }
  return gid;
}

const enregistrerGrille = (id) => wrap('enregistrerGrille', async (req, res) => {
  const b = req.body || {};
  const err = validerGrille(b);
  if (err) return res.status(400).json({ success: false, message: err });
  const client = await connecter();
  try {
    await client.query('BEGIN');
    const gid = await ecrireGrille(client, req, id ? req.params.id : null, b);
    await client.query('COMMIT');
    res.status(id ? 200 : 201).json({ success: true, id: gid });
  } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
});
const creerGrille = enregistrerGrille(false);
const modifierGrille = enregistrerGrille(true);

const supprimerGrille = wrap('supprimerGrille', async (req, res) => {
  await pool.query('DELETE FROM finance_grilles WHERE id = $1 AND etablissement_id = $2', [req.params.id, req.etablissementId]);
  res.json({ success: true });
});

// Recopie la grille d'une année vers la suivante (dates d'échéance décalées d'un an).
const dupliquerAnnee = wrap('dupliquerAnnee', async (req, res) => {
  const { de, vers } = req.body || {};
  if (!de || !vers || de === vers) return res.status(400).json({ success: false, message: 'Années invalides.' });
  const deja = await pool.query('SELECT 1 FROM finance_grilles WHERE etablissement_id=$1 AND annee_academique=$2 LIMIT 1', [req.etablissementId, vers]);
  if (deja.rows.length) return res.status(409).json({ success: false, message: `La grille ${vers} existe déjà.` });
  const source = await chargerGrilles(req.etablissementId, de);
  if (!source.length) return res.status(404).json({ success: false, message: `Aucune grille pour ${de}.` });
  const client = await connecter();
  try {
    await client.query('BEGIN');
    for (const g of source) {
      await ecrireGrille(client, req, null, { ...g, annee_academique: vers,
        tranches: g.tranches.map((t) => ({ ...t, echeance: t.echeance ? `${Number(t.echeance.slice(0, 4)) + 1}${t.echeance.slice(4)}` : null })) });
    }
    await client.query('COMMIT');
    res.status(201).json({ success: true, copiees: source.length });
  } catch (e) {
    await pool.query('DELETE FROM finance_grilles WHERE etablissement_id=$1 AND annee_academique=$2', [req.etablissementId, vers]).catch(() => {});
    throw e;
  } finally { client.release(); }
});

// ═══ ÉTUDIANTS : situations, impayés (admin) ═══════════════════════════════
const getEtudiants = wrap('getEtudiants', async (req, res) => {
  const annee = await anneeCourante(req);
  const { filiere_id, niveau, q, statut } = req.query;
  const [etus, grilles, tot] = await Promise.all([
    pool.query(`${SQL_ETUDIANTS} WHERE e.etablissement_id = $1 ORDER BY e.nom, e.prenoms`, [req.etablissementId]),
    chargerGrilles(req.etablissementId, annee), totauxParEtudiant(req.etablissementId, annee)]);
  const recherche = String(q || '').trim().toLowerCase();
  let lignes = etus.rows
    .filter((e) => !filiere_id || String(e.filiere_id) === String(filiere_id))
    .filter((e) => !niveau || String(e.niveau || '').toLowerCase() === String(niveau).toLowerCase())
    .filter((e) => !recherche || `${e.nom} ${e.prenoms} ${e.matricule}`.toLowerCase().includes(recherche))
    .map((e) => {
      const s = situationPour(e, grilles, tot);
      return { id: e.id, matricule: e.matricule, nom: e.nom, prenoms: e.prenoms, filiere_nom: e.filiere_nom,
        niveau: e.niveau, tel_parent: e.tel_parent, total_du: s.net_a_payer, paye: s.paye, reste: s.reste,
        montant_en_retard: s.montant_en_retard, statut: s.statut, bloque: s.bloque, derniere_relance: s.derniere_relance };
    });
  if (statut === 'impayes') lignes = lignes.filter((l) => l.reste > 0);
  else if (statut) lignes = lignes.filter((l) => l.statut === statut);
  res.json({ success: true, annee, data: lignes });
});

async function detailEtudiant(etab, etu, annee) {
  const [situation, ver, rem, rel] = await Promise.all([
    situationEtudiant(etab, etu, annee),
    pool.query(`SELECT * FROM finance_versements WHERE etudiant_id = $1 AND annee_academique = $2 ORDER BY created_at DESC`, [etu.id, annee]),
    pool.query(`SELECT * FROM finance_remises WHERE etudiant_id = $1 AND annee_academique = $2 ORDER BY created_at DESC`, [etu.id, annee]),
    pool.query(`SELECT * FROM finance_relances WHERE etudiant_id = $1 ORDER BY created_at DESC LIMIT 10`, [etu.id])]);
  return {
    etudiant: { id: etu.id, matricule: etu.matricule, nom: etu.nom, prenoms: etu.prenoms, filiere_nom: etu.filiere_nom, niveau: etu.niveau, tel_parent: etu.tel_parent },
    situation,
    versements: ver.rows.map((v) => ({ ...v, montant: nombre(v.montant), mode_label: LABELS_MODE[v.mode] || v.mode })),
    remises: rem.rows.map((r) => ({ ...r, montant: nombre(r.montant) })),
    relances: rel.rows,
  };
}

const getEtudiantDetail = wrap('getEtudiantDetail', async (req, res) => {
  const etu = await trouverEtudiant(req.etablissementId, req.params.id);
  if (!etu) return res.status(404).json({ success: false, message: 'Étudiant introuvable.' });
  res.json({ success: true, annee: await anneeCourante(req), ...(await detailEtudiant(req.etablissementId, etu, await anneeCourante(req))) });
});

// ═══ ENCAISSEMENT (admin) ═══════════════════════════════════════════════════
async function creerRecu(client, versementId, annee) {
  const num = numeroRecu(annee, versementId);
  await client.query('UPDATE finance_versements SET numero_recu = $2 WHERE id = $1', [versementId, num]);
  return num;
}

const encaisser = wrap('encaisser', async (req, res) => {
  const { etudiant_id, montant, mode, reference, note } = req.body || {};
  const m = nombre(montant);
  if (!etudiant_id || !(m > 0)) return res.status(400).json({ success: false, message: 'Étudiant et montant requis.' });
  if (!MODES_MANUELS.includes(mode || 'especes')) return res.status(400).json({ success: false, message: 'Mode de paiement invalide.' });
  if (['virement', 'cheque'].includes(mode) && !String(reference || '').trim()) {
    return res.status(400).json({ success: false, message: mode === 'cheque' ? 'Le numéro du chèque est obligatoire.' : 'La référence du virement est obligatoire.' });
  }
  const etu = await trouverEtudiant(req.etablissementId, etudiant_id);
  if (!etu) return res.status(404).json({ success: false, message: 'Étudiant introuvable.' });
  const annee = await anneeCourante(req);
  const avant = await situationEtudiant(req.etablissementId, etu, annee);
  if (m > avant.reste && !req.body.autoriser_excedent) {
    return res.status(409).json({ success: false, code: 'EXCEDENT',
      message: `Ce montant dépasse le reste à payer (${avant.reste} FCFA). Confirme pour enregistrer un trop-perçu.` });
  }
  const client = await connecter();
  let ligne;
  try {
    await client.query('BEGIN');
    const r = await client.query(
      `INSERT INTO finance_versements (etablissement_id, etudiant_id, annee_academique, montant, mode, reference, note, statut, enregistre_par, confirmed_at, canal)
       VALUES ($1,$2,$3,$4,$5,$6,$7,'reussi',$8,NOW(),'caisse') RETURNING *`,
      [req.etablissementId, etu.id, annee, m, mode || 'especes', reference || null, note || null, qui(req)]);
    ligne = r.rows[0];
    try { ligne.numero_recu = await creerRecu(client, ligne.id, annee); }
    catch (e) { await pool.query('DELETE FROM finance_versements WHERE id = $1', [ligne.id]).catch(() => {}); throw e; }
    await client.query('COMMIT');
  } catch (e) { await client.query('ROLLBACK'); throw e; } finally { client.release(); }
  notifierPaiement(etu, m).catch(() => {});
  res.status(201).json({ success: true, versement_id: ligne.id, numero_recu: ligne.numero_recu });
});

async function notifierPaiement(etu, m) {
  const texte = `Votre paiement de ${m} FCFA a bien été enregistré. Merci.`;
  if (etu.user_id) await envoyerNotificationAuto(etu.user_id, 'Paiement reçu', texte, 'scolarite', { tab: 'scolarite' });
}

const annulerVersement = wrap('annulerVersement', async (req, res) => {
  const motif = String(req.body?.motif || '').trim();
  if (!motif) return res.status(400).json({ success: false, message: "Le motif d'annulation est obligatoire." });
  const r = await pool.query(
    `UPDATE finance_versements SET statut='annule', motif_annulation=$3
     WHERE id=$1 AND etablissement_id=$2 AND statut='reussi' RETURNING id`, [req.params.id, req.etablissementId, motif]);
  if (!r.rows.length) return res.status(404).json({ success: false, message: 'Versement introuvable ou déjà annulé.' });
  res.json({ success: true });
});

// Reçu : données prêtes pour le PDF généré par l'application.
// 1re édition = « Original », les suivantes = « Duplicata n° x » (traçabilité des réimpressions).
const getRecu = wrap('getRecu', async (req, res) => {
  const v = await pool.query(`SELECT * FROM finance_versements WHERE id = $1 AND etablissement_id = $2`, [req.params.id, req.etablissementId]);
  const ver = v.rows[0];
  if (!ver || ver.statut !== 'reussi') return res.status(404).json({ success: false, message: 'Reçu introuvable.' });
  const etu = await etudiantAutorise(req, ver.etudiant_id);
  if (!etu) return res.status(403).json({ success: false, message: 'Accès refusé.' });
  const etab = await pool.query('SELECT nom, sigle, ville, telephone, adresse FROM etablissements WHERE id = $1', [req.etablissementId]);
  const s = await situationEtudiant(req.etablissementId, etu, ver.annee_academique);
  const imp = await pool.query(
    `UPDATE finance_versements SET recu_impressions = COALESCE(recu_impressions, 0) + 1 WHERE id = $1 RETURNING recu_impressions`, [ver.id]);
  const nb = nombre(imp.rows[0]?.recu_impressions) || 1;
  res.json({ success: true, recu: {
    numero: ver.numero_recu || numeroRecu(ver.annee_academique, ver.id), date: ver.confirmed_at || ver.created_at,
    montant: nombre(ver.montant), montant_lettres: enLettres(ver.montant),
    mode: LABELS_MODE[ver.mode] || ver.mode, reference: ver.reference || ver.transaction_id,
    caissier: ver.canal === 'caisse' ? (ver.enregistre_par || null) : null, canal: ver.canal || 'caisse',
    original: nb <= 1, duplicata_numero: nb <= 1 ? 0 : nb - 1,
    annee_academique: ver.annee_academique, etablissement: etab.rows[0] || {},
    etudiant: { nom: etu.nom, prenoms: etu.prenoms, matricule: etu.matricule, filiere: etu.filiere_nom, niveau: etu.niveau },
    total_paye: s.paye, reste: s.reste, net_a_payer: s.net_a_payer } });
});

// ═══ REMISES, BLOCAGE, RELANCES (admin) ═════════════════════════════════════
const ajouterRemise = wrap('ajouterRemise', async (req, res) => {
  const { etudiant_id, montant, motif } = req.body || {};
  if (!etudiant_id || !(nombre(montant) > 0)) return res.status(400).json({ success: false, message: 'Étudiant et montant requis.' });
  const etu = await trouverEtudiant(req.etablissementId, etudiant_id);
  if (!etu) return res.status(404).json({ success: false, message: 'Étudiant introuvable.' });
  await pool.query(
    `INSERT INTO finance_remises (etablissement_id, etudiant_id, annee_academique, montant, motif, created_by) VALUES ($1,$2,$3,$4,$5,$6)`,
    [req.etablissementId, etu.id, await anneeCourante(req), nombre(montant), motif || null, qui(req)]);
  res.status(201).json({ success: true });
});
const supprimerRemise = wrap('supprimerRemise', async (req, res) => {
  await pool.query('DELETE FROM finance_remises WHERE id = $1 AND etablissement_id = $2', [req.params.id, req.etablissementId]);
  res.json({ success: true });
});

const definirBlocage = wrap('definirBlocage', async (req, res) => {
  const { etudiant_ids, bloque, motif } = req.body || {};
  const ids = Array.isArray(etudiant_ids) ? etudiant_ids : [];
  if (!ids.length) return res.status(400).json({ success: false, message: 'Aucun étudiant sélectionné.' });
  let n = 0;
  for (const id of ids) {
    const etu = await trouverEtudiant(req.etablissementId, id);
    if (!etu) continue;
    if (bloque === false) {
      await pool.query('DELETE FROM finance_blocages WHERE etudiant_id = $1', [etu.id]);
    } else {
      await pool.query(
        `INSERT INTO finance_blocages (etudiant_id, etablissement_id, bloque, motif, par) VALUES ($1,$2,TRUE,$3,$4)
         ON CONFLICT (etudiant_id) DO UPDATE SET bloque = TRUE, motif = EXCLUDED.motif, par = EXCLUDED.par, depuis = NOW()`,
        [etu.id, req.etablissementId, motif || 'Scolarité à régulariser', qui(req)]);
    }
    n += 1;
  }
  res.json({ success: true, modifies: n });
});

function numeroWhatsApp(tel) {
  const d = String(tel || '').replace(/\D/g, '');
  if (!d) return null;
  return d.length === 8 ? `226${d}` : d;
}
const fcfa = (n) => Number(n).toLocaleString('fr-FR').replace(/ | /g, ' ');

// Relance : notification (étudiant + parent), SMS (parent), lien WhatsApp (envoi par l'admin).
// La relance est aussi enregistrée : elle apparaît sur la page « Ma scolarité » de l'étudiant et du parent.
const relancer = wrap('relancer', async (req, res) => {
  const { etudiant_ids, tous_impayes, canaux, message } = req.body || {};
  const choix = (Array.isArray(canaux) ? canaux : ['notification']).filter((c) => ['notification', 'sms', 'whatsapp'].includes(c));
  if (!choix.length) return res.status(400).json({ success: false, message: 'Choisis au moins un canal.' });
  const annee = await anneeCourante(req);
  const [etus, grilles, tot] = await Promise.all([
    pool.query(`${SQL_ETUDIANTS} WHERE e.etablissement_id = $1`, [req.etablissementId]),
    chargerGrilles(req.etablissementId, annee), totauxParEtudiant(req.etablissementId, annee)]);
  const ciblesIds = new Set((etudiant_ids || []).map(String));
  const cibles = etus.rows.filter((e) => tous_impayes ? situationPour(e, grilles, tot).reste > 0 : ciblesIds.has(String(e.id)));
  if (!cibles.length) return res.status(400).json({ success: false, message: 'Aucun étudiant à relancer.' });

  const bilan = { notifications: 0, sms: 0, whatsapp: [], ignores: 0 };
  for (const e of cibles) {
    const s = situationPour(e, grilles, tot);
    if (s.reste <= 0) { bilan.ignores += 1; continue; }
    const texte = (message && String(message).trim()) ||
      `Bonjour, il reste ${fcfa(s.reste)} FCFA de scolarité à régler pour ${e.prenoms} ${e.nom}` +
      (s.montant_en_retard > 0 ? ` (dont ${fcfa(s.montant_en_retard)} FCFA en retard)` : '') + `. Merci de passer à l'administration ou de payer depuis l'application.`;
    const faits = [];
    if (choix.includes('notification')) {
      try {
        if (e.user_id) await envoyerNotificationAuto(e.user_id, 'Rappel de scolarité', texte, 'scolarite', { tab: 'scolarite' });
        const p = await pool.query(
          `SELECT p.user_id FROM parents p JOIN parent_etudiants pe ON pe.parent_id = p.id WHERE pe.etudiant_id = $1 AND p.user_id IS NOT NULL`, [e.id]);
        for (const row of p.rows) await envoyerNotificationAuto(row.user_id, 'Rappel de scolarité', texte, 'scolarite', { tab: 'scolarite' });
        bilan.notifications += 1; faits.push('notification');
      } catch (err) { console.error('[relancer] notif', err.message); }
    }
    if (choix.includes('sms') && e.tel_parent) {
      try {
        const rs = await envoyerSMS(e.tel_parent, `ScolarHub : ${texte}`.slice(0, 300));
        if (rs && rs.success === false) console.error('[relancer] sms', rs.error);
        else { bilan.sms += 1; faits.push('sms'); }
      } catch (err) { console.error('[relancer] sms', err.message); }
    }
    if (choix.includes('whatsapp')) {
      const num = numeroWhatsApp(e.tel_parent);
      if (num) { bilan.whatsapp.push({ etudiant_id: e.id, nom: `${e.prenoms} ${e.nom}`, url: `https://wa.me/${num}?text=${encodeURIComponent(texte)}` }); faits.push('whatsapp'); }
    }
    // La page « Ma scolarité » est toujours mise à jour (4e canal, sans condition).
    await pool.query(
      `INSERT INTO finance_relances (etablissement_id, etudiant_id, message, canaux, envoye_par) VALUES ($1,$2,$3,$4,$5)`,
      [req.etablissementId, e.id, texte, [...faits, 'page'], qui(req)]);
  }
  res.json({ success: true, ...bilan, cibles: cibles.length });
});

// ═══ ÉTUDIANT / PARENT ══════════════════════════════════════════════════════
async function reponseSituation(req, res, etu) {
  const annee = await anneeCourante(req);
  const d = await detailEtudiant(req.etablissementId, etu, annee);
  const derniere = d.relances[0] || null;
  res.json({ success: true, annee, etudiant: d.etudiant, situation: d.situation,
    versements: d.versements.filter((v) => v.statut === 'reussi'),
    rappel: derniere && d.situation.reste > 0 ? { message: derniere.message, date: derniere.created_at } : null });
}
const getMaSituation = wrap('getMaSituation', async (req, res) => {
  const etu = await etudiantDeUser(req);
  if (!etu) return res.status(404).json({ success: false, message: 'Profil étudiant introuvable.' });
  await reponseSituation(req, res, etu);
});
const getSituationEnfant = wrap('getSituationEnfant', async (req, res) => {
  const etu = await etudiantAutorise(req, req.params.etudiantId);
  if (!etu) return res.status(403).json({ success: false, message: 'Accès refusé à cet étudiant.' });
  await reponseSituation(req, res, etu);
});

// Paiement en ligne (étudiant ou parent) — via le fournisseur branchable.
const payer = wrap('payer', async (req, res) => {
  const { etudiant_id, montant, operateur, telephone } = req.body || {};
  const m = nombre(montant);
  if (!(m > 0) || !telephone || !operateur) return res.status(400).json({ success: false, message: 'Montant, téléphone et opérateur requis.' });
  if (!OPERATEURS.includes(operateur)) return res.status(400).json({ success: false, message: `Opérateur invalide. Choix : ${OPERATEURS.join(', ')}` });
  let etu;
  if (req.user.role === 'parent') etu = await etudiantAutorise(req, etudiant_id);
  else etu = await etudiantDeUser(req);
  if (!etu) return res.status(403).json({ success: false, message: 'Accès refusé.' });
  const annee = await anneeCourante(req);
  const s = await situationEtudiant(req.etablissementId, etu, annee);
  if (s.reste <= 0) return res.status(400).json({ success: false, message: 'Aucun montant à payer.' });
  if (m > s.reste) return res.status(400).json({ success: false, message: `Le montant dépasse ce qu'il reste à payer (${s.reste} FCFA).` });

  const init = await getProvider().initier({ montant: m, telephone, operateur, description: `Scolarité — ${etu.prenoms} ${etu.nom}` });
  if (!init.success) return res.status(502).json({ success: false, message: init.error || "Échec de l'initialisation du paiement." });
  const r = await pool.query(
    `INSERT INTO finance_versements (etablissement_id, etudiant_id, annee_academique, montant, mode, operateur, telephone, reference, statut, enregistre_par, canal)
     VALUES ($1,$2,$3,$4,$5,$5,$6,$7,'en_attente',$8,'en_ligne') RETURNING id`,
    [req.etablissementId, etu.id, annee, m, operateur, telephone, init.reference, qui(req)]);
  res.status(201).json({ success: true, versement_id: r.rows[0].id, reference: init.reference,
    otp_requis: init.otp_requis !== false, payment_url: init.payment_url || null });
});

// Valide un versement en attente (code OTP ou retour du fournisseur) et crée le reçu.
async function validerVersement(versementId, transactionId) {
  // UPDATE conditionnel : un seul appel (OTP ou webhook) peut faire passer le versement à « réussi ».
  const u = await pool.query(
    `UPDATE finance_versements SET statut='reussi', transaction_id=$2, confirmed_at=NOW()
      WHERE id=$1 AND statut <> 'reussi' RETURNING *`, [versementId, transactionId || null]);
  if (!u.rows.length) return (await pool.query('SELECT * FROM finance_versements WHERE id = $1', [versementId])).rows[0] || null;
  const v = u.rows[0];
  v.numero_recu = await creerRecu(pool, versementId, v.annee_academique);
  return v;
}

const confirmerPaiement = wrap('confirmerPaiement', async (req, res) => {
  const v = (await pool.query('SELECT * FROM finance_versements WHERE id = $1 AND etablissement_id = $2', [req.params.id, req.etablissementId])).rows[0];
  if (!v) return res.status(404).json({ success: false, message: 'Paiement introuvable.' });
  const etu = await etudiantAutorise(req, v.etudiant_id);
  if (!etu) return res.status(403).json({ success: false, message: 'Accès refusé.' });
  if (v.statut === 'reussi') return res.status(400).json({ success: false, message: 'Ce paiement est déjà confirmé.' });
  const conf = await getProvider().confirmer({ reference: v.reference, code: req.body?.code });
  if (!conf.success) return res.status(402).json({ success: false, message: conf.error || 'Paiement refusé.' });
  const ok = await validerVersement(v.id, conf.transaction_id);
  notifierPaiement(etu, nombre(v.montant)).catch(() => {});
  res.json({ success: true, message: 'Paiement confirmé.', versement_id: v.id, numero_recu: ok?.numero_recu });
});

// Retour automatique du fournisseur (quand tu auras l'API Orange Money, etc.).
// Le service de paiement doit exposer traiterWebhook(req) → { reference, transaction_id, succes }.
const webhook = async (req, res) => {
  try {
    const p = getProvider();
    if (typeof p.traiterWebhook !== 'function') return res.status(501).json({ message: 'Webhook non pris en charge par le fournisseur actuel.' });
    const evt = await p.traiterWebhook(req);
    if (!evt || !evt.reference) return res.status(400).json({ message: 'Notification invalide.' });
    const v = (await pool.query('SELECT id FROM finance_versements WHERE reference = $1', [evt.reference])).rows[0];
    if (v && evt.succes) await validerVersement(v.id, evt.transaction_id);
    else if (v) await pool.query(`UPDATE finance_versements SET statut='echoue' WHERE id=$1 AND statut='en_attente'`, [v.id]);
    res.json({ ok: true });
  } catch (e) { console.error('[finances.webhook]', e); res.status(500).json({ message: 'Erreur webhook.' }); }
};

// ═══ DÉPENSES (admin) ═══════════════════════════════════════════════════════
const getDepenses = wrap('getDepenses', async (req, res) => {
  const annee = await anneeCourante(req);
  const f = fenetreAnnee(annee);
  const du = req.query.du || f.du; const au = req.query.au || f.au;
  const r = await pool.query(
    `SELECT * FROM finance_depenses WHERE etablissement_id = $1 AND date_depense BETWEEN $2 AND $3
     ${req.query.categorie ? 'AND categorie = $4' : ''} ORDER BY date_depense DESC, id DESC`,
    req.query.categorie ? [req.etablissementId, du, au, req.query.categorie] : [req.etablissementId, du, au]);
  const data = r.rows.map((d) => ({ ...d, montant: nombre(d.montant), date_depense: dateISO(d.date_depense) }));
  res.json({ success: true, annee, categories: CATEGORIES_DEPENSES, total: data.reduce((s, d) => s + d.montant, 0), data });
});
const creerDepense = wrap('creerDepense', async (req, res) => {
  const { libelle, categorie, montant, date_depense, beneficiaire, justificatif_url } = req.body || {};
  if (!libelle || !(nombre(montant) > 0)) return res.status(400).json({ success: false, message: 'Libellé et montant requis.' });
  const r = await pool.query(
    `INSERT INTO finance_depenses (etablissement_id, libelle, categorie, montant, date_depense, beneficiaire, justificatif_url, created_by)
     VALUES ($1,$2,$3,$4,COALESCE($5, CURRENT_DATE),$6,$7,$8) RETURNING id`,
    [req.etablissementId, String(libelle).trim(), CATEGORIES_DEPENSES.includes(categorie) ? categorie : 'autre',
      nombre(montant), date_depense || null, beneficiaire || null, justificatif_url || null, qui(req)]);
  res.status(201).json({ success: true, id: r.rows[0].id });
});
const supprimerDepense = wrap('supprimerDepense', async (req, res) => {
  await pool.query('DELETE FROM finance_depenses WHERE id = $1 AND etablissement_id = $2', [req.params.id, req.etablissementId]);
  res.json({ success: true });
});

// ═══ RAPPORT (admin) ════════════════════════════════════════════════════════
const getRapport = wrap('getRapport', async (req, res) => {
  const etab = req.etablissementId;
  const annee = await anneeCourante(req);
  const { du, au } = fenetreAnnee(annee);
  const [etus, grilles, tot, recM, depM, modes, cats] = await Promise.all([
    pool.query(`${SQL_ETUDIANTS} WHERE e.etablissement_id = $1`, [etab]),
    chargerGrilles(etab, annee), totauxParEtudiant(etab, annee),
    pool.query(`SELECT to_char(COALESCE(confirmed_at, created_at), 'YYYY-MM') AS mois, SUM(montant) AS s FROM finance_versements
                WHERE etablissement_id=$1 AND statut='reussi' AND annee_academique=$2 GROUP BY 1`, [etab, annee]),
    pool.query(`SELECT to_char(date_depense, 'YYYY-MM') AS mois, SUM(montant) AS s FROM finance_depenses
                WHERE etablissement_id=$1 AND date_depense BETWEEN $2 AND $3 GROUP BY 1`, [etab, du, au]),
    pool.query(`SELECT mode, SUM(montant) AS s, COUNT(*) AS n FROM finance_versements
                WHERE etablissement_id=$1 AND statut='reussi' AND annee_academique=$2 GROUP BY mode ORDER BY s DESC`, [etab, annee]),
    pool.query(`SELECT categorie, SUM(montant) AS s FROM finance_depenses
                WHERE etablissement_id=$1 AND date_depense BETWEEN $2 AND $3 GROUP BY categorie ORDER BY s DESC`, [etab, du, au])]);

  let attendu = 0, encaisse = 0, nbImpayes = 0, nbRetard = 0, retard = 0;
  for (const e of etus.rows) {
    const s = situationPour(e, grilles, tot);
    attendu += s.net_a_payer; encaisse += s.paye;
    if (s.reste > 0) nbImpayes += 1;
    if (s.montant_en_retard > 0) { nbRetard += 1; retard += s.montant_en_retard; }
  }
  const nbBloques = Object.keys(tot.blocages).length;

  const mois = [];
  const [y1] = du.split('-').map(Number);
  for (let i = 0; i < 12; i += 1) {
    const d = new Date(Date.UTC(y1, 8 + i, 1));
    mois.push(`${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`);
  }
  const rm = Object.fromEntries(recM.rows.map((r) => [r.mois, nombre(r.s)]));
  const dm = Object.fromEntries(depM.rows.map((r) => [r.mois, nombre(r.s)]));
  const mensuel = mois.map((k) => ({ mois: k, recettes: rm[k] || 0, depenses: dm[k] || 0 }));
  const recettes = mensuel.reduce((s, m) => s + m.recettes, 0);
  const depenses = mensuel.reduce((s, m) => s + m.depenses, 0);

  res.json({ success: true, annee,
    kpis: { attendu, encaisse, reste: Math.max(0, attendu - encaisse), taux: attendu > 0 ? Math.round((encaisse / attendu) * 1000) / 10 : 0,
      nb_impayes: nbImpayes, nb_en_retard: nbRetard, montant_en_retard: retard, nb_bloques: nbBloques },
    recettes, depenses, solde: recettes - depenses, mensuel,
    par_mode: modes.rows.map((r) => ({ mode: r.mode, label: LABELS_MODE[r.mode] || r.mode, total: nombre(r.s), nombre: Number(r.n) })),
    depenses_par_categorie: cats.rows.map((r) => ({ categorie: r.categorie, total: nombre(r.s) })) });
});

// ═══ BLOCAGE : à appeler depuis les contrôleurs de notes et de bulletins ═════
// Renvoie { bloque, motif }. Si les tables finances n'existent pas encore, ne bloque jamais.
async function accesNotesBloque(etudiantId) {
  try {
    const r = await pool.query('SELECT motif FROM finance_blocages WHERE etudiant_id = $1 AND bloque = TRUE', [etudiantId]);
    return r.rows.length ? { bloque: true, motif: r.rows[0].motif } : { bloque: false };
  } catch (e) { return { bloque: false }; }
}
async function accesNotesBloqueParUser(userId) {
  try {
    const r = await pool.query(
      `SELECT b.motif FROM finance_blocages b JOIN etudiants e ON e.id = b.etudiant_id
       WHERE e.user_id = $1 AND b.bloque = TRUE`, [userId]);
    return r.rows.length ? { bloque: true, motif: r.rows[0].motif } : { bloque: false };
  } catch (e) { return { bloque: false }; }
}
// Liste d'ids d'étudiants bloqués parmi ceux donnés (pour masquer des moyennes en lot).
async function etudiantsBloques(ids) {
  try {
    if (!ids.length) return new Set();
    const r = await pool.query('SELECT etudiant_id::text AS k FROM finance_blocages WHERE bloque = TRUE AND etudiant_id::text = ANY($1::text[])', [ids.map(String)]);
    return new Set(r.rows.map((x) => x.k));
  } catch (e) { return new Set(); }
}
const MESSAGE_BLOCAGE = "L'accès à vos notes et bulletins est suspendu : votre scolarité doit être régularisée auprès de l'administration.";


// ═══ CAISSE : droits, journée de caisse, clôture, journal ══════════════════
const getDroits = wrap('getDroits', async (req, res) => {
  const role = req.user?.role;
  res.json({ success: true, role, admin: ROLES_ADMIN.includes(role), caisse: ROLES_CAISSE.includes(role) });
});

const SQL_CAISSE_DU_JOUR = `FROM finance_versements v JOIN etudiants e ON e.id = v.etudiant_id
  WHERE v.etablissement_id = $1 AND v.statut = 'reussi' AND v.canal = 'caisse'
    AND COALESCE(v.confirmed_at, v.created_at)::date = $2::date AND v.enregistre_par = $3`;

function totauxCaisse(lignes) {
  const parMode = {}; let attendu = 0; let autres = 0;
  for (const l of lignes) {
    const m = nombre(l.montant);
    parMode[l.mode] = (parMode[l.mode] || 0) + m;
    if (l.mode === 'especes') attendu += m; else autres += m;
  }
  return { par_mode: parMode, attendu_especes: attendu, autres_modes: autres, total: attendu + autres };
}

// Journée de caisse du caissier connecté (l'administration peut consulter un autre caissier).
const getCaisseJour = wrap('getCaisseJour', async (req, res) => {
  const date = jourValide(req.query.date);
  const caissier = estAdmin(req) && req.query.caissier ? String(req.query.caissier) : qui(req);
  const r = await pool.query(
    `SELECT v.id, v.montant, v.mode, v.reference, v.numero_recu, v.cloture_id,
            COALESCE(v.confirmed_at, v.created_at) AS date, e.nom, e.prenoms, e.matricule ${SQL_CAISSE_DU_JOUR}
     ORDER BY COALESCE(v.confirmed_at, v.created_at) DESC`, [req.etablissementId, date, caissier]);
  const ouvertes = r.rows.filter((l) => !l.cloture_id);
  const cl = await pool.query(
    `SELECT * FROM finance_clotures WHERE etablissement_id = $1 AND date_caisse = $2::date AND caissier = $3 ORDER BY created_at DESC`,
    [req.etablissementId, date, caissier]);
  res.json({ success: true, date, caissier, versements: r.rows, a_cloturer: totauxCaisse(ouvertes),
    nb_a_cloturer: ouvertes.length, clotures: cl.rows });
});

const cloturerCaisse = wrap('cloturerCaisse', async (req, res) => {
  const date = jourValide(req.body?.date);
  const brut = req.body?.especes_comptees;
  if (brut === undefined || brut === null || String(brut).trim() === '' || !(Number(brut) >= 0)) {
    return res.status(400).json({ success: false, message: "Saisis le montant d'espèces réellement compté en caisse." });
  }
  const comptes = nombre(brut);
  const moi = qui(req);
  const r = await pool.query(
    `SELECT v.id, v.montant, v.mode ${SQL_CAISSE_DU_JOUR} AND v.cloture_id IS NULL`, [req.etablissementId, date, moi]);
  if (!r.rows.length) return res.status(409).json({ success: false, message: 'Aucun encaissement à clôturer pour cette journée.' });
  const t = totauxCaisse(r.rows);
  const ecart = comptes - t.attendu_especes;
  const note = String(req.body?.note || '').trim();
  if (ecart !== 0 && !note) {
    return res.status(400).json({ success: false, code: 'ECART',
      message: `Écart de ${ecart > 0 ? '+' : ''}${ecart} FCFA : explique-le dans la note avant de clôturer.` });
  }
  const ins = await pool.query(
    `INSERT INTO finance_clotures (etablissement_id, date_caisse, caissier, nb_versements, attendu_especes, compte_especes, ecart, autres_modes, note)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9) RETURNING id`,
    [req.etablissementId, date, moi, r.rows.length, t.attendu_especes, comptes, ecart, t.autres_modes, note || null]);
  await pool.query(
    `UPDATE finance_versements v SET cloture_id = $4
      WHERE v.etablissement_id = $1 AND v.statut = 'reussi' AND v.canal = 'caisse'
        AND COALESCE(v.confirmed_at, v.created_at)::date = $2::date AND v.enregistre_par = $3 AND v.cloture_id IS NULL`,
    [req.etablissementId, date, moi, ins.rows[0].id]);
  res.status(201).json({ success: true, id: ins.rows[0].id, attendu_especes: t.attendu_especes, compte_especes: comptes, ecart });
});

// Historique des clôtures (administration) : repérer les écarts.
const getClotures = wrap('getClotures', async (req, res) => {
  const fin = jourValide(req.query.au);
  const debut = req.query.du ? jourValide(req.query.du) : new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10);
  const r = await pool.query(
    `SELECT * FROM finance_clotures WHERE etablissement_id = $1 AND date_caisse BETWEEN $2::date AND $3::date
     ORDER BY date_caisse DESC, created_at DESC LIMIT 300`, [req.etablissementId, debut, fin]);
  const ecarts = r.rows.reduce((s, l) => s + nombre(l.ecart), 0);
  res.json({ success: true, du: debut, au: fin, data: r.rows, total_ecarts: ecarts });
});

// Journal global des versements (filtres + totaux), pour la caisse et la comptabilité.
const getVersements = wrap('getVersements', async (req, res) => {
  const { du, au, mode, caissier, q, statut, canal } = req.query;
  const w = ['v.etablissement_id = $1']; const p = [req.etablissementId];
  const add = (cond, val) => { p.push(val); w.push(cond.replace('?', `$${p.length}`)); };
  if (du) add("COALESCE(v.confirmed_at, v.created_at)::date >= ?::date", jourValide(du));
  if (au) add("COALESCE(v.confirmed_at, v.created_at)::date <= ?::date", jourValide(au));
  if (mode) add('v.mode = ?', String(mode));
  if (canal) add('v.canal = ?', String(canal));
  if (caissier) add("LOWER(COALESCE(v.enregistre_par, '')) LIKE ?", `%${String(caissier).toLowerCase()}%`);
  if (q) add("LOWER(COALESCE(e.nom,'') || ' ' || COALESCE(e.prenoms,'') || ' ' || COALESCE(e.matricule,'') || ' ' || COALESCE(v.reference,'') || ' ' || COALESCE(v.numero_recu,'')) LIKE ?", `%${String(q).toLowerCase()}%`);
  if (statut === 'annule') w.push("v.statut = 'annule'");
  else if (statut !== 'tous') w.push("v.statut = 'reussi'");
  else w.push("v.statut IN ('reussi','annule')");
  const r = await pool.query(
    `SELECT v.id, v.montant, v.mode, v.reference, v.numero_recu, v.statut, v.canal, v.enregistre_par, v.motif_annulation,
            v.cloture_id, COALESCE(v.confirmed_at, v.created_at) AS date, v.annee_academique,
            e.nom, e.prenoms, e.matricule, e.filiere_nom, e.niveau
     FROM finance_versements v JOIN etudiants e ON e.id = v.etudiant_id
     WHERE ${w.join(' AND ')} ORDER BY COALESCE(v.confirmed_at, v.created_at) DESC LIMIT 1000`, p);
  const ok = r.rows.filter((l) => l.statut === 'reussi');
  const parMode = {};
  for (const l of ok) parMode[l.mode] = (parMode[l.mode] || 0) + nombre(l.montant);
  res.json({ success: true, data: r.rows, total: ok.reduce((s, l) => s + nombre(l.montant), 0),
    nb: ok.length, par_mode: parMode, tronque: r.rows.length >= 1000 });
});

module.exports = {
  getDroits, getCaisseJour, cloturerCaisse, getClotures, getVersements,
  getGrilles, creerGrille, modifierGrille, supprimerGrille, dupliquerAnnee,
  getEtudiants, getEtudiantDetail, encaisser, annulerVersement, getRecu,
  ajouterRemise, supprimerRemise, definirBlocage, relancer,
  getMaSituation, getSituationEnfant, payer, confirmerPaiement, webhook,
  getDepenses, creerDepense, supprimerDepense, getRapport,
  accesNotesBloque, accesNotesBloqueParUser, etudiantsBloques, MESSAGE_BLOCAGE,
};
