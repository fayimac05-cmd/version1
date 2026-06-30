const express = require('express');
const router = express.Router();
const notesController = require('../controllers/notes.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

// Notes de l'étudiant connecté
router.get('/etudiant', authMiddleware, notesController.getNotesEtudiant);

// Export PDF des bulletins
router.get('/bulletin/:etudiantId', authMiddleware, notesController.generateBulletinPdf);

// Sessions de notes
router.post('/sessions', authMiddleware, notesController.createGradeSession);
router.get('/sessions', authMiddleware, notesController.getGradeSessions);
router.patch('/sessions/:session_id/send', authMiddleware, notesController.markSessionSent);

module.exports = router;
