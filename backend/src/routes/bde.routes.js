const express = require('express');
const router = express.Router();

router.get('/', (req, res) => res.json({ message: 'BDE route OK' }));

module.exports = router;
