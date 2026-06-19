const express = require('express');
const router = express.Router();
const etudiantsController = require('../controllers/etudiants.controller');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');

router.get('/', authMiddleware, etudiantsController.listEtudiants);
router.post('/', authMiddleware, requireRole('admin'), etudiantsController.inscrireEtudiant);

module.exports = router;
