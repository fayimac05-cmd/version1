const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth.middleware');
const canauxController = require('../controllers/canaux.controller');

router.get('/', authMiddleware, canauxController.getCanaux);
router.get('/:id', authMiddleware, canauxController.getCanalById);
router.get('/:id/messages', authMiddleware, canauxController.getCanalMessages);
router.post('/:id/messages', authMiddleware, canauxController.postCanalMessage);

module.exports = router;
