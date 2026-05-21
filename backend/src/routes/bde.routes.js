const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: 'bde OK' }));
module.exports = router;
