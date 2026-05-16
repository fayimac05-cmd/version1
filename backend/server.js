const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

// Routes Imports
const filiereRoutes = require('./routes/filieres');
const moduleRoutes = require('./routes/modules');
const professeurRoutes = require('./routes/professeurs');
const membreRoutes = require('./routes/membres');
const etudiantRoutes = require('./routes/etudiants');
const statistiqueRoutes = require('./routes/statistiques');

// Routes Middleware
app.use('/api/filieres', filiereRoutes);
app.use('/api/modules', moduleRoutes);
app.use('/api/professeurs', professeurRoutes);
app.use('/api/membres', membreRoutes);
app.use('/api/etudiants', etudiantRoutes);
app.use('/api/statistiques', statistiqueRoutes);

// Base Route
app.get('/', (req, res) => {
  res.json({ message: 'Welcome to ScolarHub API' });
});

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
