const express = require('express');
const router = express.Router();
const etudiantsController = require('../controllers/etudiants.controller');
const { authMiddleware, requireRole } = require('../middleware/auth.middleware');

router.get('/', authMiddleware, etudiantsController.listEtudiants);
router.post('/', authMiddleware, requireRole('admin'), etudiantsController.inscrireEtudiant);
// Route publique — activation du compte lors de la première connexion
router.post('/finaliser', etudiantsController.finaliserPremiereConnexion);

// Matricule automatique, paramètres d'inscription, inscriptions à valider (admin).
// ⚠️ Doivent rester AVANT les routes '/:id/...' pour ne pas être confondues avec un id.
router.get('/prochain-matricule', authMiddleware, requireRole('admin'), etudiantsController.prochainMatricule);
router.get('/parametres-inscription', authMiddleware, requireRole('admin'), etudiantsController.getParametresInscription);
router.put('/parametres-inscription', authMiddleware, requireRole('admin'), etudiantsController.setParametresInscription);
router.get('/en-attente', authMiddleware, requireRole('admin'), etudiantsController.listerEnAttente);
router.post('/valider-inscriptions', authMiddleware, requireRole('admin'), etudiantsController.validerInscriptions);
router.post('/refuser-inscriptions', authMiddleware, requireRole('admin'), etudiantsController.refuserInscriptions);

router.get('/delegues', authMiddleware, etudiantsController.getDelegues);
router.get('/stats/inscriptions', authMiddleware, requireRole('admin'), etudiantsController.getStatsInscriptions);
router.post('/:id/nommer-delegue', authMiddleware, etudiantsController.nommerDelegue);
router.patch('/:id/revoquer-delegue', authMiddleware, etudiantsController.revoquerDelegue);
router.get('/bde', authMiddleware, etudiantsController.getBde);
router.post('/:id/nommer-bde', authMiddleware, etudiantsController.nommerBde);
router.patch('/:id/revoquer-bde', authMiddleware, etudiantsController.revoquerBde);

module.exports = router;