const express = require('express');
const router = express.Router();
const { generateBulletinPdf } = require('../controllers/notes.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.get('/', (req, res) => res.json({ message: 'notes OK' }));

// Export PDF des bulletins
router.get('/bulletin/:etudiantId', authMiddleware, generateBulletinPdf);

module.exports = router;
