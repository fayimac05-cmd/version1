const jwt = require('jsonwebtoken');
const socketService = require('../services/socket.service');
const MessageModel = require('../models/messageModel');
const CanalModel = require('../models/canalModel');
const { canWriteCanal } = require('../services/canalPermissions.service');
const { getUserById, formatAuteur } = require('../services/user.service');

module.exports = (io) => {
  socketService.init(io);

  io.on('connection', (socket) => {
    console.log('Socket connecte : ' + socket.id);

    socket.on('auth', async ({ token, userId }) => {
      try {
        let user;
        if (token) {
          user = jwt.verify(token, process.env.JWT_SECRET);
        } else if (userId) {
          user = await getUserById(userId);
        }

        if (!user) {
          socket.emit('auth_error', { message: 'Authentification socket invalide.' });
          return;
        }

        const dbUser = await getUserById(user.id);
        socket.user = { ...user, ...dbUser };
        socketService.registerUser(user.id, socket.id);

        const etablissementId = dbUser?.etablissement_id || user.etablissement_id;
        if (etablissementId) {
          socket.join(`etablissement_${etablissementId}`);
        }
        if (dbUser?.filiere) {
          socket.join(`filiere_${dbUser.filiere}`);
        }

        socket.emit('auth_ok', { userId: user.id, role: socket.user.role });
        console.log(`Socket authentifie : ${user.id} (${user.role})`);
      } catch (err) {
        socket.emit('auth_error', { message: 'Token invalide.' });
      }
    });

    socket.on('join_room', ({ roomId }) => {
      if (roomId) socket.join(roomId);
    });

    socket.on('join_canal', async ({ canalId }) => {
      if (!socket.user || !canalId) return;
      socket.join(`canal_${canalId}`);
      socket.emit('joined_canal', { canalId });
    });

    socket.on('leave_canal', ({ canalId }) => {
      if (canalId) socket.leave(`canal_${canalId}`);
    });

    socket.on('canal_message', async ({ canalId, contenu, type, fichier_url }) => {
      if (!socket.user || !canalId || !contenu) return;

      try {
        const canal = await CanalModel.findById(canalId);
        if (!canal || !canWriteCanal(socket.user, canal)) {
          socket.emit('error', { message: 'Publication refusée dans ce canal.' });
          return;
        }

        const message = await MessageModel.create({
          canal_id: canalId,
          auteur_id: socket.user.id,
          contenu: contenu.trim(),
          type: type || 'texte',
          fichier_url: fichier_url || null,
        });

        const dbUser = await getUserById(socket.user.id);
        const payload = {
          ...message,
          canal_id: canalId,
          canal_type: canal.type,
          auteur: formatAuteur(dbUser),
        };

        socketService.emitToCanal(canalId, 'new_canal_message', payload);
      } catch (err) {
        socket.emit('error', { message: err.message });
      }
    });

    socket.on('private_message', ({ toUserId, contenu, conversationId, type }) => {
      if (!socket.user || !contenu) return;
      const payload = {
        auteur_id: socket.user.id,
        contenu,
        type: type || 'texte',
        conversation_id: conversationId,
        created_at: new Date().toISOString(),
      };
      socketService.emitToUser(toUserId, 'new_private_message', payload);
    });

    socket.on('admin_notification', ({ etablissementId, notification }) => {
      if (!socket.user || !['admin', 'professeur'].includes(socket.user.role)) return;
      socketService.emitToEtablissement(etablissementId, 'notification', notification);
    });

    socket.on('disconnect', () => {
      if (socket.user?.id) socketService.unregisterUser(socket.user.id);
    });
  });
};
