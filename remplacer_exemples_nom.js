#!/usr/bin/env node
// ============================================================================
// Remplace les NOMS / PRÉNOMS D'EXEMPLE des champs de saisie (hintText, hint,
// labelText, placeholder…) par TON nom et TON prénom.
//   Ex : "Ex: OUÉDRAOGO"  ->  "Ex: KOURAOGO"      "Ex: Mamadou" -> "Ex: Ibrahim"
//
// Utilisation (à la racine du projet Flutter, ScolarHub OU GoDeliver) :
//   node remplacer_exemples_nom.js            -> APERÇU (ne modifie rien)
//   node remplacer_exemples_nom.js --go       -> applique les changements
//   node remplacer_exemples_nom.js --go --dir lib --ext dart,html
//   node remplacer_exemples_nom.js --nom CHEKETE --prenom Ibrahim --go
//
// Sécurité : seules les lignes qui ressemblent à un texte d'aide de champ
// (hint / label / placeholder, ou « Ex: » / « Ex. » / « ex: ») sont touchées.
// Les vraies données (listes, mocks, messages…) ne sont jamais modifiées.
// Annule tout avec :  git restore .   (ou git checkout -- lib)
// ============================================================================
const fs = require('fs');
const path = require('path');

// ───────────────────────── À MODIFIER ICI ──────────────────────────────────
const CONFIG = {
  NOM: 'KOURAOGO',      // affiché en MAJUSCULES quand l'exemple d'origine l'est
  PRENOM: 'Ibrahim',    // tel quel (ex. 'Ibrahim')
  // Exemples d'e-mails : prenom.nom@email.com (mettre false pour ne pas toucher)
  REMPLACER_EMAILS: true,
  DOMAINE_EMAIL: 'email.com',
};

// Noms de famille d'exemple à remplacer (sans accents, insensible à la casse).
const NOMS_EXEMPLE = ['ouedraogo', 'kabore', 'sawadogo', 'traore', 'compaore',
  'zongo', 'ouattara', 'sankara', 'tapsoba', 'nikiema', 'sere', 'diallo', 'konate'];
// Prénoms d'exemple à remplacer.
const PRENOMS_EXEMPLE = ['mamadou', 'issa', 'aminata', 'fatou', 'moussa', 'ali',
  'awa', 'salif', 'adama', 'ousmane', 'abdoul', 'rasmane', 'boureima'];
// ────────────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const opt = (n, d) => { const i = args.indexOf('--' + n); return i >= 0 && args[i + 1] ? args[i + 1] : d; };
const GO = args.includes('--go');
const NOM = opt('nom', CONFIG.NOM);
const PRENOM = opt('prenom', CONFIG.PRENOM);
const DIR = opt('dir', 'lib');
const EXTS = opt('ext', 'dart').split(',').map(e => '.' + e.trim().replace(/^\./, ''));

const sansAccent = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '');
const motEchappe = l => l.map(x => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')).join('|');
// Variantes avec accents courantes (OUÉDRAOGO, KABORÉ, SÉRÉ…) : on compare sans accents.
const RE_MOT = /[A-Za-zÀ-ÖØ-öø-ÿ]+/g;

// Une ligne est « un texte d'aide » si elle contient hint/label/placeholder
// ou un préfixe d'exemple (Ex: / Ex. / Ex : / ex: / Exemple :).
const RE_LIGNE_AIDE = /(hint(Text)?|label(Text)?|placeholder|helper(Text)?)\s*[:=]|['"`]\s*(ex|exemple)\s*[.:]/i;
const RE_EMAIL = /\b([a-z0-9._-]+)@(email\.com|exemple\.com|example\.com|gmail\.com|ist\.bf)\b/gi;

function transformerLigne(ligne) {
  if (!RE_LIGNE_AIDE.test(ligne)) return ligne;
  // On ne travaille QUE sur le contenu des chaînes ('…' ou "…") de la ligne.
  return ligne.replace(/(['"])((?:\\.|(?!\1).)*)\1/g, (tout, q, contenu) => {
    if (!/\b(ex|exemple)\s*[.:]|@/i.test(contenu) && !/^\s*[A-ZÀ-Ý][\p{L}' -]*\s*$/u.test(contenu)) return tout;
    let nouveau = contenu;

    // 1) e-mails d'exemple (issa.kabore@email.com -> ibrahim.kouraogo@email.com)
    if (CONFIG.REMPLACER_EMAILS) {
      nouveau = nouveau.replace(RE_EMAIL, (m, local, dom) => {
        const l = sansAccent(local.toLowerCase());
        const contientNom = NOMS_EXEMPLE.some(n => l.includes(n)) || PRENOMS_EXEMPLE.some(p => l.includes(p));
        if (!contientNom) return m;
        const pre = sansAccent(PRENOM).toLowerCase().replace(/\s+/g, '');
        const nom = sansAccent(NOM).toLowerCase().replace(/\s+/g, '');
        return `${pre}.${nom}@${dom}`;
      });
    }

    // 2) noms et prénoms d'exemple (mot entier, accents ignorés)
    nouveau = nouveau.replace(RE_MOT, mot => {
      const k = sansAccent(mot).toLowerCase();
      if (NOMS_EXEMPLE.includes(k)) {
        const majuscule = mot === mot.toUpperCase() && mot.length > 1;
        return majuscule ? NOM.toUpperCase() : NOM[0].toUpperCase() + NOM.slice(1).toLowerCase();
      }
      if (PRENOMS_EXEMPLE.includes(k)) return PRENOM;
      return mot;
    });
    return nouveau === contenu ? tout : q + nouveau + q;
  });
}

function parcourir(dossier, sortie) {
  for (const f of fs.readdirSync(dossier, { withFileTypes: true })) {
    if (f.name.startsWith('.') || ['build', 'node_modules', 'ios', 'android', 'linux', 'windows', 'macos'].includes(f.name)) continue;
    const p = path.join(dossier, f.name);
    if (f.isDirectory()) parcourir(p, sortie);
    else if (EXTS.includes(path.extname(f.name))) sortie.push(p);
  }
}

if (!fs.existsSync(DIR)) {
  console.error(`Dossier introuvable : ${DIR}  (lance le script à la racine du projet, ou utilise --dir)`);
  process.exit(1);
}
const fichiers = [];
parcourir(DIR, fichiers);

let total = 0, nbFichiers = 0;
for (const fichier of fichiers) {
  const brut = fs.readFileSync(fichier, 'utf8');
  const crlf = brut.includes('\r\n');
  const lignes = brut.replace(/\r\n/g, '\n').split('\n');
  let modifie = false;
  lignes.forEach((l, i) => {
    const n = transformerLigne(l);
    if (n !== l) {
      modifie = true; total++;
      console.log(`${fichier}:${i + 1}\n   - ${l.trim()}\n   + ${n.trim()}`);
      lignes[i] = n;
    }
  });
  if (modifie) {
    nbFichiers++;
    if (GO) fs.writeFileSync(fichier, lignes.join(crlf ? '\r\n' : '\n'), 'utf8');
  }
}
console.log(`\n${total} ligne(s) dans ${nbFichiers} fichier(s) ${GO ? 'MODIFIÉE(S)' : 'à modifier (aperçu — relance avec --go pour appliquer)'}.`);
console.log(`Nom : ${NOM.toUpperCase()}   Prénom : ${PRENOM}`);
