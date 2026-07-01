const express = require('express');
const router = express.Router();
const appelsController = require('../controllers/appels.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.post('/', authMiddleware, appelsController.createAppel);
router.get('/', authMiddleware, appelsController.getAppels);
router.get('/:id', authMiddleware, appelsController.getAppelDetail);

module.exports = router;
