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
const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: '*', methods: ['GET', 'POST'] },
});

app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
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
app.use('/api/messages',      require('./src/routes/messages.routes'));
app.use('/api/canaux',        require('./src/routes/canaux.routes'));
app.use('/api/tickets',       require('./src/routes/tickets.routes'));
app.use('/api/bde',           require('./src/routes/bde.routes'));
app.use('/api/edt',           require('./src/routes/edt.routes'));
app.use('/api/ia',            require('./src/routes/ia.routes'));
app.use('/api/notifications', require('./src/routes/notifications.routes'));

app.get('/', (req, res) => res.json({ message: 'ScolarHub API — IST Ouaga 2000', status: 'OK' }));

require('./src/socket/socket')(io);

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Serveur demarré sur http://localhost:${PORT}`));

module.exports = { app, io };
