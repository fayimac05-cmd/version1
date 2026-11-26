// backend/src/routes/finances.routes.js
// À monter dans app.js / server.js :  app.use('/api/finances', require('./routes/finances.routes'));
const express = require('express');
const router = express.Router();
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const c = require('../controllers/finances.controller');

const admin = [authMiddleware, requireRole('admin', 'direction')];
// Personnel de caisse : encaisse, imprime les reçus, clôture sa caisse (pas de remise, d'annulation, de blocage...).
const caisse = [authMiddleware, requireRole('admin', 'direction', 'caissier', 'scolarite', 'comptable', 'comptabilite')];

// Retour automatique du fournisseur de paiement (sans jeton : le fournisseur n'en a pas)
router.post('/webhook', c.webhook);

// Étudiant / parent
router.get('/ma-situation', authMiddleware, c.getMaSituation); // tout compte étudiant (délégué, BDE...) : le contrôleur retrouve l'étudiant
router.get('/enfant/:etudiantId/situation', authMiddleware, c.getSituationEnfant);
router.post('/payer', authMiddleware, c.payer);
router.post('/payer/:id/confirmer', authMiddleware, c.confirmerPaiement);
router.get('/versements/:id/recu', authMiddleware, c.getRecu);

// Administration
router.get('/grilles', ...admin, c.getGrilles);
router.post('/grilles', ...admin, c.creerGrille);
router.post('/grilles/dupliquer', ...admin, c.dupliquerAnnee);
router.put('/grilles/:id', ...admin, c.modifierGrille);
router.delete('/grilles/:id', ...admin, c.supprimerGrille);

router.get('/droits', authMiddleware, c.getDroits);
router.get('/etudiants', ...caisse, c.getEtudiants);
router.get('/etudiants/:id', ...caisse, c.getEtudiantDetail);
router.post('/versements', ...caisse, c.encaisser);
router.get('/versements', ...caisse, c.getVersements);
router.get('/caisse/jour', ...caisse, c.getCaisseJour);
router.post('/caisse/cloture', ...caisse, c.cloturerCaisse);
router.get('/caisse/clotures', ...admin, c.getClotures);
router.post('/versements/:id/annuler', ...admin, c.annulerVersement);
router.post('/remises', ...admin, c.ajouterRemise);
router.delete('/remises/:id', ...admin, c.supprimerRemise);
router.post('/blocage', ...admin, c.definirBlocage);
router.post('/relances', ...admin, c.relancer);

router.get('/depenses', ...admin, c.getDepenses);
router.post('/depenses', ...admin, c.creerDepense);
router.delete('/depenses/:id', ...admin, c.supprimerDepense);
router.get('/rapport', ...admin, c.getRapport);

module.exports = router;
