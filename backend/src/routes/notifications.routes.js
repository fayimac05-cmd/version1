const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth.middleware');
const notificationsController = require('../controllers/notifications.controller');

router.get('/', authMiddleware, notificationsController.getNotifications);
router.patch('/:id/lue', authMiddleware, notificationsController.marquerCommeLue);
router.delete('/lire-tout', authMiddleware, notificationsController.marquerToutesLues);

module.exports = router;
