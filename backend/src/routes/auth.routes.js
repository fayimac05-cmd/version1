const express = require('express');
const router = express.Router();
const { login, setupPassword, me, changePassword, register, lookup } = require('../controllers/auth.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.post('/login',           login);
router.get('/lookup',           lookup);
router.post('/register',        register);
router.post('/setup-password',  setupPassword);
router.get('/me',               authMiddleware, me);
router.post('/change-password', authMiddleware, changePassword);

module.exports = router;
