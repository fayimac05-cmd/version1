const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: 'professeurs OK' }));
module.exports = router;
