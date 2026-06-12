const express = require('express');
const router = express.Router();
const coursController = require('../controllers/cours.controller');
const { authMiddleware } = require('../middleware/auth.middleware');
const { upload, uploadToCloudinary } = require('../middleware/upload.middleware');

router.post('/', authMiddleware, upload.single('file'), uploadToCloudinary('cours'), coursController.uploadCours);
router.get('/', authMiddleware, coursController.getCours);

module.exports = router;
