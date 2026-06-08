const express = require('express');
const router = express.Router();
const etudiantsController = require('../controllers/etudiants.controller');

router.get('/', etudiantsController.listEtudiants);
router.post('/', etudiantsController.inscrireEtudiant);

module.exports = router;
