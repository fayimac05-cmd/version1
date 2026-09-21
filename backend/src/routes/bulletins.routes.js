const express = require('express');
const router = express.Router();
const bulletinsController = require('../controllers/bulletins.controller');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');

// Prévision de moyenne — tableau notes+moyennes par module, sans coefficient (admin)
router.get('/prevision', authMiddleware, requireRole('admin'), bulletinsController.getPrevisionMoyenne);
router.post('/prevision/envoyer', authMiddleware, requireRole('admin'), bulletinsController.envoyerPrevision);

// Prévisions reçues par l'étudiant connecté
router.get('/mes-previsions', authMiddleware, bulletinsController.getMesPrevisions);

// Préparation du bulletin — calcul automatique des moyennes par filière/niveau/semestre (admin)
router.get('/preparation', authMiddleware, requireRole('admin'), bulletinsController.getPreparationBulletin);

// Publication des bulletins — statut Validé/Ajourné/Invalidé coché manuellement par l'admin
router.post('/publier', authMiddleware, requireRole('admin'), bulletinsController.publierBulletins);

// Bulletin de l'étudiant connecté — uniquement ses bulletins publiés
router.get('/mon-bulletin', authMiddleware, bulletinsController.getMonBulletin);

module.exports = router;