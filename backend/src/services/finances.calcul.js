// Calculs de scolarité — fonctions pures (sans base de données), faciles à tester.
// Placer dans : backend/src/services/finances.calcul.js

const ORDRE_TYPE = { inscription: 0, scolarite: 1, autre: 2 };

const norm = (v) => (v === null || v === undefined ? '' : String(v).trim().toLowerCase());

// Une ligne de grille s'applique à un étudiant si chacun de ses critères
// (domaine, filière, niveau) est vide (= « tous ») ou identique à celui de l'étudiant.
function grilleApplicable(g, etu) {
  if (g.actif === false) return false;
  if (g.filiere_id !== null && g.filiere_id !== undefined && String(g.filiere_id) !== String(etu.filiere_id)) return false;
  if (norm(g.niveau) && norm(g.niveau) !== norm(etu.niveau)) return false;
  if (norm(g.domaine) && norm(g.domaine) !== norm(etu.domaine)) return false;
  return true;
}

function dateISO(d) {
  if (!d) return null;
  if (typeof d === 'string') return d.slice(0, 10);
  return new Date(d).toISOString().slice(0, 10);
}

/**
 * @param {object} p
 * @param {Array}  p.grilles    lignes de grille applicables, chacune avec .tranches[]
 * @param {number} p.remises    total des remises accordées
 * @param {number} p.paye       total des versements réussis
 * @param {string} [p.aujourdhui] 'YYYY-MM-DD' (par défaut : aujourd'hui)
 */
function calculerSituation({ grilles, remises = 0, paye = 0, aujourdhui }) {
  const today = aujourdhui || new Date().toISOString().slice(0, 10);
  const lignes = [...grilles].sort((a, b) =>
    (ORDRE_TYPE[a.type] ?? 9) - (ORDRE_TYPE[b.type] ?? 9) || a.id - b.id);

  const total = lignes.reduce((s, g) => s + Number(g.montant_total), 0);
  const remise = Math.min(Number(remises) || 0, total);
  const net = total - remise;
  const verse = Number(paye) || 0;
  const reste = Math.max(0, net - verse);

  // Crédit disponible = versements + remises, imputé tranche par tranche, dans l'ordre.
  let credit = verse + remise;
  let enRetard = 0;
  let prochaine = null;

  const lignesOut = lignes.map((g) => {
    let tranches = [...(g.tranches || [])].sort((a, b) => a.numero - b.numero)
      .map((t) => ({ ...t, montant: Number(t.montant), echeance: dateISO(t.echeance) }));
    const somme = tranches.reduce((s, t) => s + t.montant, 0);
    if (!tranches.length) {
      tranches = [{ id: null, numero: 1, libelle: g.libelle, montant: Number(g.montant_total), echeance: null }];
    } else if (somme < Number(g.montant_total)) {
      tranches.push({ id: null, numero: tranches.length + 1, libelle: 'Solde', montant: Number(g.montant_total) - somme, echeance: null });
    }
    const tr = tranches.map((t) => {
      const imputé = Math.min(credit, t.montant);
      credit -= imputé;
      const resteT = t.montant - imputé;
      let statut = 'a_payer';
      if (resteT === 0) statut = 'payee';
      else if (imputé > 0) statut = 'partielle';
      if (resteT > 0 && t.echeance && t.echeance < today) {
        statut = 'en_retard';
        enRetard += resteT;
      } else if (resteT > 0 && t.echeance && (!prochaine || t.echeance < prochaine)) {
        prochaine = t.echeance;
      }
      return { ...t, paye: imputé, reste: resteT, statut };
    });
    const payeLigne = tr.reduce((s, t) => s + t.paye, 0);
    return {
      grille_id: g.id, type: g.type, libelle: g.libelle, montant_total: Number(g.montant_total),
      paye: payeLigne, reste: Number(g.montant_total) - payeLigne, tranches: tr,
    };
  });

  let statut = 'a_jour';
  if (reste > 0 && enRetard > 0) statut = 'en_retard';
  else if (reste > 0 && verse > 0) statut = 'partiel';
  else if (reste > 0) statut = 'non_paye';
  if (total === 0) statut = 'aucun_frais';

  return {
    annee_total: total, total_du: total, remises: remise, net_a_payer: net, paye: verse,
    reste, excedent: Math.max(0, verse + remise - total),
    montant_en_retard: enRetard, prochaine_echeance: prochaine, statut, lignes: lignesOut,
  };
}

// Numéro de reçu lisible : R-2026-000123
function numeroRecu(annee, id) {
  const a = String(annee || new Date().getFullYear()).slice(0, 4);
  return `R-${a}-${String(id).padStart(6, '0')}`;
}


// ── Montant en lettres (français, FCFA) ─────────────────────────────────────
const UNITES = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze',
  'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf'];
const DIZAINES = ['', '', 'vingt', 'trente', 'quarante', 'cinquante', 'soixante'];

function moinsDeCent(n, final) {
  if (n < 20) return UNITES[n];
  const d = Math.floor(n / 10); const u = n % 10;
  if (d <= 6) return u === 0 ? DIZAINES[d] : `${DIZAINES[d]}${u === 1 ? ' et ' : '-'}${UNITES[u]}`;
  if (d === 7) return u === 1 ? 'soixante et onze' : `soixante-${UNITES[10 + u]}`;
  if (d === 8) return u === 0 ? (final ? 'quatre-vingts' : 'quatre-vingt') : `quatre-vingt-${UNITES[u]}`;
  return `quatre-vingt-${UNITES[10 + u]}`; // 90-99
}
function moinsDeMille(n, final) {
  const c = Math.floor(n / 100); const r = n % 100;
  let out = '';
  if (c > 0) {
    out = c === 1 ? 'cent' : `${UNITES[c]} cent`;
    if (r === 0 && c > 1 && final) out += 's';
  }
  if (r > 0) out += (out ? ' ' : '') + moinsDeCent(r, final);
  return out;
}
function enLettres(valeur) {
  let n = Math.floor(Math.abs(Number(valeur) || 0));
  if (n === 0) return 'zéro franc CFA';
  const parts = []; let reste = n;
  const milliards = Math.floor(reste / 1e9); reste %= 1e9;
  const millions = Math.floor(reste / 1e6); reste %= 1e6;
  const milliers = Math.floor(reste / 1e3); const unites = reste % 1e3;
  if (milliards) parts.push(`${moinsDeMille(milliards, false)} milliard${milliards > 1 ? 's' : ''}`);
  if (millions) parts.push(`${moinsDeMille(millions, false)} million${millions > 1 ? 's' : ''}`);
  if (milliers) parts.push(milliers === 1 ? 'mille' : `${moinsDeMille(milliers, false)} mille`);
  if (unites) parts.push(moinsDeMille(unites, true));
  const texte = parts.join(' ');
  const de = (unites === 0 && milliers === 0 && (millions || milliards)) ? ' de' : '';
  return `${texte}${de} franc${n > 1 ? 's' : ''} CFA`;
}

module.exports = { grilleApplicable, calculerSituation, numeroRecu, dateISO, enLettres };
