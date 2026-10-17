// ============================================================
// src/routes/plateforme.routes.js
// Montage : app.use('/api/plateforme', require('./routes/plateforme.routes'));
// Protégé par la clé PLATFORM_ADMIN_KEY (variable d'environnement, ≥ 20 caractères),
// envoyée dans l'en-tête « x-platform-key ». Sans clé configurée, tout est refusé.
// L'interface web (/api/plateforme/ui) n'est qu'une page sans secret : la clé
// se saisit dans le navigateur et n'est jamais stockée côté serveur.
// ============================================================
const express = require('express');
const crypto = require('crypto');
const path = require('path');
const c = require('../controllers/plateforme.controller');

const router = express.Router();
const DOSSIER_UI = path.join(__dirname, '..', 'plateforme');

// Limite des essais ratés : 10 par 15 minutes et par adresse IP (mémoire).
const echecs = new Map();
const FENETRE = 15 * 60 * 1000;
const MAX_ECHECS = 10;
const bloque = (ip) => {
  const e = echecs.get(ip);
  return !!e && Date.now() - e.debut < FENETRE && e.n >= MAX_ECHECS;
};
const noterEchec = (ip) => {
  const e = echecs.get(ip);
  if (!e || Date.now() - e.debut >= FENETRE) echecs.set(ip, { n: 1, debut: Date.now() });
  else e.n += 1;
};

function cleValide(fournie) {
  const attendue = process.env.PLATFORM_ADMIN_KEY || '';
  if (attendue.length < 20) return false; // clé absente ou trop courte : refusé
  const a = crypto.createHash('sha256').update(String(fournie || '')).digest();
  const b = crypto.createHash('sha256').update(attendue).digest();
  return crypto.timingSafeEqual(a, b);
}

function exigerCle(req, res, next) {
  if ((process.env.PLATFORM_ADMIN_KEY || '').length < 20) {
    return res.status(503).json({ success: false, message: "PLATFORM_ADMIN_KEY n'est pas configurée sur le serveur (20 caractères minimum)." });
  }
  const ip = req.ip;
  if (bloque(ip)) return res.status(429).json({ success: false, message: 'Trop d\'essais. Réessayez plus tard.' });
  if (!cleValide(req.get('x-platform-key'))) {
    noterEchec(ip);
    return res.status(401).json({ success: false, message: 'Clé plateforme invalide.' });
  }
  next();
}

// Interface web (pages sans secret)
router.get('/ui', (req, res) => res.sendFile(path.join(DOSSIER_UI, 'index.html')));
router.get('/ui/app.js', (req, res) => res.sendFile(path.join(DOSSIER_UI, 'app.js')));

// API protégée
router.get('/etablissements', exigerCle, c.listerEtablissements);
router.post('/etablissements', exigerCle, c.creerEtablissement);
router.patch('/etablissements/:id', exigerCle, c.modifierEtablissement);
router.post('/etablissements/:id/super-admin', exigerCle, c.ajouterSuperAdmin);

module.exports = router;
