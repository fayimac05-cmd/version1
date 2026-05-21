const express = require('express');
const router = express.Router();
const statistiqueController = require('../controllers/statistiques.controller');

router.get('/filieres', statistiqueController.getFiliereStats);

module.exports = router;
