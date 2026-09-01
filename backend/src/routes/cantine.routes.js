const express = require('express');
const router = express.Router();
const cantineController = require('../controllers/cantine.controller');

// Menu routes
router.get('/menu', cantineController.getMenu);
router.post('/menu', cantineController.addPlat);
router.put('/menu/:id', cantineController.updatePlat);
router.delete('/menu/:id', cantineController.deletePlat);

// Commandes routes
router.post('/commandes', cantineController.creerCommande);
router.get('/commandes/mes-commandes', cantineController.getMesCommandes);
router.get('/commandes', cantineController.getAllCommandes);
router.patch('/commandes/:id/statut', cantineController.updateStatutCommande);

module.exports = router;
