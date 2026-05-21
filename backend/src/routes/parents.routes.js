const express = require('express');
const router = express.Router();
router.get('/', (req, res) => res.json({ message: 'parents OK' }));
module.exports = router;
