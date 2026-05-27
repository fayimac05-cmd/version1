const express = require('express');
const router = express.Router();
const { chat, getHistorique } = require('../controllers/ia.controller');

// POST /api/ia/chat
router.post('/chat', chat);

// GET /api/ia/historique
router.get('/historique', getHistorique);

module.exports = router;