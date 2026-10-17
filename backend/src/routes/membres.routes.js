const express = require('express');
const router = express.Router();
const membresController = require('../controllers/membres.controller');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');

// Toutes les routes exigent un administrateur connecté : le jeton fournit
// l'établissement (req.etablissementId) utilisé pour filtrer les données.
router.use(authMiddleware, requireRole('admin'));

router.get('/', membresController.getAllMembres);
router.post('/', membresController.createMembre);
router.patch('/:id/permissions', membresController.updatePermissions);
router.delete('/:id', membresController.deleteMembre);

module.exports = router;