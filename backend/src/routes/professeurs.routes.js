const express = require('express');
const router = express.Router();
const professeursController = require('../controllers/professeurs.controller');
const { authMiddleware } = require('../middleware/auth.middleware');

router.get('/profile', authMiddleware, professeursController.getProfile);
router.put('/profile', authMiddleware, professeursController.updateProfile);
router.get('/classes', authMiddleware, professeursController.getClasses);
router.get('/modules', authMiddleware, professeursController.getModules);
router.get('/classes/:filiere_id/students', authMiddleware, professeursController.getStudentsByFiliere);

module.exports = router;
