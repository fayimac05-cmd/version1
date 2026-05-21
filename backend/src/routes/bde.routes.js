const express = require('express');
const router = express.Router();
const {
  getNotifications,
  marquerCommeLue,
  marquerToutesLues,
} = require('../controllers/notifications.controller');

// GET /api/notifications
router.get('/', getNotifications);

// PATCH /api/notifications/:id/lue
router.patch('/:id/lue', marquerCommeLue);

// DELETE /api/notifications/lire-tout
router.delete('/lire-tout', marquerToutesLues);

module.exports = router;