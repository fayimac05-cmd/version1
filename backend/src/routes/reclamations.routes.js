const express = require('express');
const router = express.Router();
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');
const reclamationsController = require('../controllers/reclamations.controller');

// Étudiant
router.post('/', authMiddleware, reclamationsController.createReclamation);
router.get('/mes-reclamations', authMiddleware, reclamationsController.getMesReclamations);

// Admin (déclarées avant /:id pour ne pas être capturées par la route paramétrique)
router.get('/en-attente/count', authMiddleware, requireRole('admin'), reclamationsController.getNombreEnAttente);
router.get('/', authMiddleware, requireRole('admin'), reclamationsController.getAllReclamations);
router.patch('/:id/transferer', authMiddleware, requireRole('admin'), reclamationsController.transfererReclamation);
router.patch('/:id/repondre', authMiddleware, requireRole('admin'), reclamationsController.repondreReclamation);
router.patch('/:id/rejeter', authMiddleware, requireRole('admin'), reclamationsController.rejeterReclamation);

module.exports = router;
