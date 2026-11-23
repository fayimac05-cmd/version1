// Ajoute date_naissance et lieu_naissance aux données de bulletins.controller.js
// Usage (depuis le dossier backend) :  node patch-bulletins-naissance.js controllers/bulletins.controller.js
const fs = require('fs');
const chemin = process.argv[2];
if (!chemin) { console.error('Indique le chemin de bulletins.controller.js'); process.exit(1); }
let s = fs.readFileSync(chemin, 'utf8');
const crlf = s.includes('\r\n');
s = s.replace(/\r\n/g, '\n');

const NAIS = "COALESCE(date_naissance, (SELECT u.date_naissance FROM users u WHERE u.id = etudiants.user_id)) AS date_naissance, lieu_naissance";
const remplacements = [
  // 1. liste des étudiants de la classe (préparation des bulletins)
  [/SELECT id, matricule, nom, prenoms FROM etudiants WHERE filiere_id = \$1 AND niveau = \$2/,
   "SELECT id, matricule, nom, prenoms, " + NAIS + " FROM etudiants WHERE filiere_id = $1 AND niveau = $2"],
  // 2. objet intermédiaire par étudiant
  [/etudiant_id: e\.id, matricule: e\.matricule, nom: e\.nom, prenoms: e\.prenoms, modules: modulesEtudiant/,
   "etudiant_id: e.id, matricule: e.matricule, nom: e.nom, prenoms: e.prenoms, date_naissance: e.date_naissance, lieu_naissance: e.lieu_naissance, modules: modulesEtudiant"],
  // 3. réponse finale de la préparation
  [/(matricule: e\.matricule,\n\s*nom: e\.nom,\n\s*prenoms: e\.prenoms,\n)(\s*)(filiere_nom: filiereNom,)/,
   "$1$2date_naissance: e.date_naissance,\n$2lieu_naissance: e.lieu_naissance,\n$2$3"],
  // 4. bulletin de l'étudiant connecté
  [/SELECT id, nom, prenoms, filiere_nom, niveau FROM etudiants WHERE user_id = \$1/,
   "SELECT id, nom, prenoms, filiere_nom, niveau, " + NAIS + " FROM etudiants WHERE user_id = $1"],
  [/(niveau: etudiant\.niveau,\n)(\s*)(\},)/,
   "$1$2    date_naissance: etudiant.date_naissance,\n$2    lieu_naissance: etudiant.lieu_naissance,\n$2$3"],
];
let ok = 0;
for (const [motif, rempl] of remplacements) {
  if (motif.test(s)) { s = s.replace(motif, rempl); ok++; }
  else console.warn('Motif introuvable (à vérifier à la main) :', String(motif).slice(0, 70));
}
if (crlf) s = s.replace(/\n/g, '\r\n');
fs.writeFileSync(chemin, s);
console.log(ok + '/' + remplacements.length + ' modifications appliquées.');
