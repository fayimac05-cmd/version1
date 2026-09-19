const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth.middleware');
const { upload, uploadToCloudinary } = require('../middleware/upload.middleware');
const uploadController = require('../controllers/upload.controller');

/**
 * Routes pour les uploads de fichiers
 * (copies d'examen, photos de profil/couverture, pièces jointes, etc.)
 */

// POST /api/upload/copie - Upload une copie d'examen
router.post(
  '/copie',
  authMiddleware,
  upload.single('file'),
  uploadToCloudinary('scolarhub/copies-examen'),
  uploadController.uploadExamCopy
);

// Photo de profil / couverture — ouvert à tout utilisateur connecté, quel
// que soit son rôle (étudiant, professeur, admin, parent).
router.post(
  '/photo-profil',
  authMiddleware,
  upload.single('file'),
  uploadToCloudinary('scolarhub/photos-profil'),
  uploadController.uploadPhotoProfil
);
router.delete('/photo-profil', authMiddleware, uploadController.deletePhotoProfil);

router.post(
  '/photo-couverture',
  authMiddleware,
  upload.single('file'),
  uploadToCloudinary('scolarhub/photos-couverture'),
  uploadController.uploadPhotoCouverture
);
router.delete('/photo-couverture', authMiddleware, uploadController.deletePhotoCouverture);

module.exports = router;