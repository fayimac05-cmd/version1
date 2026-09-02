const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const dotenv = require('dotenv');
const path = require('path');

dotenv.config();

const app = express();
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000').split(',');
const isLocalhostOrigin = (origin) => /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
const corsOriginCheck = (origin, callback) => {
  if (!origin || allowedOrigins.includes(origin) || (process.env.NODE_ENV !== 'production' && isLocalhostOrigin(origin))) {
    return callback(null, true);
  }
  return callback(new Error('Origine non autorisee par CORS.'));
};

let activeServer = null;
let activeIo = null;

const attachSocket = (serverInstance) => {
  const ioInstance = new Server(serverInstance, {
    cors: { origin: corsOriginCheck, methods: ['GET', 'POST'] },
  });
  app.set('io', ioInstance);
  require('./src/socket/socket')(ioInstance);
  return ioInstance;
};

app.use(helmet());
app.use(cors({
  origin: corsOriginCheck,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));
if (process.env.NODE_ENV !== 'production') {
  app.use(morgan('dev'));
}
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth',          require('./src/routes/auth.routes'));
app.use('/api/etudiants',     require('./src/routes/etudiants.routes'));
app.use('/api/professeurs',   require('./src/routes/professeurs.routes'));
app.use('/api/parents',       require('./src/routes/parents.routes'));
app.use('/api/filieres',      require('./src/routes/filieres.routes'));
app.use('/api/modules',       require('./src/routes/modules.routes'));
app.use('/api/notes',         require('./src/routes/notes.routes'));
app.use('/api/reclamations',  require('./src/routes/reclamations.routes'));
app.use('/api/annonces',      require('./src/routes/annonces.routes'));
app.use('/api/messages',      require('./src/routes/messageRoutes'));  // ← Jalil
app.use('/api/canaux',        require('./src/routes/canaux.routes'));
app.use('/api/tickets',       require('./src/routes/tickets.routes'));
app.use('/api/bde',           require('./src/routes/bde.routes'));
app.use('/api/evenements',    require('./src/routes/evenements.routes'));
app.use('/api/edt',           require('./src/routes/edt.routes'));
app.use('/api/upload',        require('./src/routes/upload.routes'));
app.use('/api/cours',         require('./src/routes/cours.routes'));
app.use('/api/ia',            require('./src/routes/ia.routes'));
app.use('/api/statistiques',  require('./src/routes/statistiques.routes'));
app.use('/api/notifications', require('./src/routes/notifications.routes'));
app.use('/api/evaluations',   require('./src/routes/evaluations.routes'));
app.use('/api/appels',        require('./src/routes/appels.routes'));
app.use('/api/risque',        require('./src/routes/risque.routes'));
app.use('/api/paiements',     require('./src/routes/paiements.routes'));

app.get('/', (req, res) => res.json({ message: 'ScolarHub API — IST Ouaga 2000', status: 'OK' }));

// Global error handler to prevent server crashes
app.use((err, req, res, next) => {
  console.error('[Global Error]', err.message);
  if (!res.headersSent) {
    res.status(500).json({ success: false, message: 'Erreur interne du serveur.' });
  }
});

const preferredPort = Number(process.env.PORT || 3000);
const candidatePorts = [preferredPort, preferredPort + 1, preferredPort + 2, 3000, 3001, 5000, 5001];

const startServer = (portIndex = 0) => {
  const port = candidatePorts[portIndex];
  const onError = (err) => {
    if (err.code === 'EADDRINUSE' && portIndex < candidatePorts.length - 1) {
      console.warn(`Port ${port} indisponible, tentative sur ${candidatePorts[portIndex + 1]}...`);
      if (activeServer && activeServer.listening) {
        activeServer.close(() => startServer(portIndex + 1));
      } else {
        startServer(portIndex + 1);
      }
      return;
    }

    console.error('Impossible de demarrer le serveur.', err);
    process.exit(1);
  };

  if (activeServer && activeServer.listening) {
    activeServer.close(() => {
      activeServer = null;
      activeIo = null;
      startServer(portIndex);
    });
    return;
  }

  activeServer = http.createServer(app);
  activeIo = attachSocket(activeServer);
  activeServer.once('error', onError);
  activeServer.listen(port, () => {
    activeServer.removeListener('error', onError);
    console.log('Serveur demarre sur http://localhost:' + port);
    if (port !== preferredPort) {
      console.log(`Le port configure ${preferredPort} etait indisponible, utilisation du port ${port}.`);
    }
  });
};

startServer();

// Prevent unhandled rejections from crashing the process
process.on('unhandledRejection', (reason, promise) => {
  console.error('[UnhandledRejection]', reason);
});

// Coupures réseau (ex: pooler Supabase qui reset une socket) : on journalise
// au lieu de laisser le process mourir.
process.on('uncaughtException', (err) => {
  console.error('[UncaughtException]', err);
});

module.exports = { app, get io() { return activeIo; } };
