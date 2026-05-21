const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: 'etudiants OK' }));
module.exports = router;
