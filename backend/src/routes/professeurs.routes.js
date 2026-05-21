const express = require('express');
const router = express.Router();
const professeurController = require('../controllers/professeurs.controller');

router.get('/', professeurController.getAllProfesseurs);
router.post('/', professeurController.createProfesseur);
router.put('/:id', professeurController.updateProfesseur);
router.delete('/:id', professeurController.deleteProfesseur);
router.get('/:id/modules', professeurController.getModulesByProfesseur);
router.patch('/assign-module', professeurController.patchModuleAssignment);

module.exports = router;
