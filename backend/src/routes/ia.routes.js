const express = require('express');
const router = express.Router();
const { chat, getHistorique } = require('../controllers/ia.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// POST /api/ia/chat - Envoyer un message a Claude
router.post('/chat', authMiddleware, chat);

// GET /api/ia/historique - Recuperer l'historique
router.get('/historique', authMiddleware, getHistorique);

module.exports = router;
