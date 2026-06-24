const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth.middleware');
const messagesController = require('../controllers/messages.controller');

router.get('/conversations', authMiddleware, messagesController.getConversations);
router.post('/conversations', authMiddleware, messagesController.createConversation);
router.get('/conversations/:id', authMiddleware, messagesController.getConversationMessages);
router.post('/conversations/:id', authMiddleware, messagesController.postConversationMessage);

module.exports = router;
