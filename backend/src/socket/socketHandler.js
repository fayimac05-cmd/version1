// ============================================================
// src/socket/socketHandler.js
// ZOUNGRANA Jalil — Messagerie temps réel Socket.io
// ============================================================

const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// Stocke les utilisateurs en ligne : { userId: socketId }
const onlineUsers = new Map();

// Référence globale à l'instance io, pour pousser des événements depuis
// n'importe quel contrôleur (ex. notifications) sans avoir accès à req.
let ioRef = null;

function initSocket(io) {
  ioRef = io;

  // ── Middleware d'authentification Socket ──────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;
    if (!token) return next(new Error('Token manquant'));

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId   = payload.id;
      socket.userRole = payload.role;
      socket.filiere  = payload.filiere_id;
      next();
    } catch {
      next(new Error('Token invalide'));
    }
  });

  // ── Connexion ─────────────────────────────────────────────
  io.on('connection', async (socket) => {
    const userId = socket.userId;
    console.log(`[Socket] Connecté : userId=${userId}`);

    // Enregistrer l'utilisateur en ligne
    onlineUsers.set(userId, socket.id);

    // Rejoindre la room personnelle (notifications)
    socket.join(`user:${userId}`);

    // Rejoindre la room de sa filière (ou les filières assignées pour un professeur)
    if (socket.filiere) {
      socket.join(`filiere:${socket.filiere}`);
    }
    if (socket.userRole === 'professeur') {
      try {
        const { rows: profFilieres } = await pool.query(
          `SELECT DISTINCT m.filiere_id 
           FROM module_professeur mp
           JOIN modules m ON m.id = mp.module_id
           WHERE mp.professeur_id IN (SELECT id FROM professeurs WHERE user_id = $1)`,
          [userId]
        );
        profFilieres.forEach(({ filiere_id }) => {
          if (filiere_id) socket.join(`filiere:${filiere_id}`);
        });
      } catch (err) {
        console.error('[Socket] Erreur chargement filières prof:', err.message);
      }
    }

    // Rejoindre toutes les rooms des canaux accessibles :
    // adhésions explicites + canaux publics (lisibles par tous ou par profs/admin)
    try {
      const publicTypes = ['administration', 'admin_filiere', 'bde', 'general'];
      if (socket.userRole === 'professeur' || socket.userRole === 'admin') {
        publicTypes.push('admin_profs');
      }
      const { rows: canaux } = await pool.query(
        `SELECT id AS canal_id FROM canaux
         WHERE type = ANY($2)
         UNION
         SELECT canal_id FROM canal_membres WHERE user_id = $1`,
        [userId, publicTypes]
      );
      canaux.forEach(({ canal_id }) => socket.join(`canal:${canal_id}`));
    } catch (err) {
      console.error('[Socket] Erreur chargement canaux:', err.message);
    }

    // Informer les contacts que l'utilisateur est en ligne
    io.emit('user:online', { userId });

    // ── Événement : envoyer un message dans un canal ──────
    socket.on('message:canal', async (data, callback) => {
      const { canalId, contenu } = data;
      if (!contenu?.trim()) return callback?.({ error: 'Contenu vide' });

      try {
        // Vérifier que l'utilisateur a le droit d'écrire (admin, prof sur admin_profs, ou membre)
        let isAuthorized = socket.userRole === 'admin';
        if (!isAuthorized) {
          const { rows: canalInfo } = await pool.query(`SELECT type FROM canaux WHERE id = $1`, [canalId]);
          if (canalInfo.length && canalInfo[0].type === 'admin_profs' && socket.userRole === 'professeur') {
            isAuthorized = true;
          }
        }
        if (!isAuthorized) {
          const { rows: access } = await pool.query(
            `SELECT role FROM canal_membres WHERE canal_id = $1 AND user_id = $2`,
            [canalId, userId]
          );
          if (access.length) isAuthorized = true;
        }

        if (!isAuthorized) return callback?.({ error: 'Accès refusé à ce canal' });

        // Persister le message
        const { rows } = await pool.query(
          `INSERT INTO messages (canal_id, auteur_id, contenu, type, created_at)
           VALUES ($1, $2, $3, 'canal', NOW())
           RETURNING id, canal_id, auteur_id, contenu, created_at`,
          [canalId, userId, contenu.trim()]
        );
        const message = rows[0];

        // Charger infos auteur
        const { rows: uRows } = await pool.query(`SELECT prenoms, nom, role FROM users WHERE id = $1`, [userId]);
        if (uRows.length) {
          message.prenoms = uRows[0].prenoms;
          message.nom = uRows[0].nom;
          message.role = uRows[0].role;
        }

        // Diffuser à tous les membres du canal
        io.to(`canal:${canalId}`).emit('message:canal', message);
        callback?.({ success: true, message });
      } catch (err) {
        console.error('[Socket] message:canal erreur:', err.message);
        callback?.({ error: 'Erreur serveur' });
      }
    });

    // ── Événement : message privé ─────────────────────────
    socket.on('message:prive', async (data, callback) => {
      const { destinataireId, contenu } = data;
      if (!contenu?.trim()) return callback?.({ error: 'Contenu vide' });

      try {
        const { rows } = await pool.query(
          `INSERT INTO messages_prives (expediteur_id, destinataire_id, contenu, created_at)
           VALUES ($1, $2, $3, NOW())
           RETURNING id, expediteur_id, destinataire_id, contenu, created_at`,
          [userId, destinataireId, contenu.trim()]
        );
        const message = rows[0];

        // Charger infos expéditeur
        const { rows: uRows } = await pool.query(`SELECT prenoms, nom, role FROM users WHERE id = $1`, [userId]);
        if (uRows.length) {
          message.prenoms = uRows[0].prenoms;
          message.nom = uRows[0].nom;
        }

        // Envoyer au destinataire et à l'expéditeur
        io.to(`user:${destinataireId}`).emit('message:prive', message);
        io.to(`user:${userId}`).emit('message:prive', message);

        callback?.({ success: true, message });
      } catch (err) {
        console.error('[Socket] message:prive erreur:', err.message);
        callback?.({ error: 'Erreur serveur' });
      }
    });

    // ── Événement : message dans groupe filière ───────────
    socket.on('message:groupe', async (data, callback) => {
      const { filiereId, contenu } = data;
      if (!contenu?.trim()) return callback?.({ error: 'Contenu vide' });

      // Vérifier que l'utilisateur appartient à la filière ou est admin/professeur
      if (String(socket.filiere) !== String(filiereId) && socket.userRole !== 'admin' && socket.userRole !== 'professeur') {
        return callback?.({ error: 'Vous n\'appartenez pas à cette filière' });
      }

      try {
        const { rows } = await pool.query(
          `INSERT INTO messages_groupe (filiere_id, auteur_id, contenu, created_at)
           VALUES ($1, $2, $3, NOW())
           RETURNING id, filiere_id, auteur_id, contenu, created_at`,
          [filiereId, userId, contenu.trim()]
        );
        const message = rows[0];

        // Charger infos auteur
        const { rows: uRows } = await pool.query(`SELECT prenoms, nom, role FROM users WHERE id = $1`, [userId]);
        if (uRows.length) {
          message.prenoms = uRows[0].prenoms;
          message.nom = uRows[0].nom;
          message.role = uRows[0].role;
        }

        // Diffuser à toute la filière
        io.to(`filiere:${filiereId}`).emit('message:groupe', message);
        callback?.({ success: true, message });
      } catch (err) {
        console.error('[Socket] message:groupe erreur:', err.message);
        callback?.({ error: 'Erreur serveur' });
      }
    });

    // ── Événement : réaction emoji ────────────────────────
    socket.on('reaction:ajout', async (data, callback) => {
      const { messageId, emoji, messageType } = data;

      try {
        await pool.query(
          `INSERT INTO reactions (message_id, user_id, emoji, message_type)
           VALUES ($1, $2, $3, $4)
           ON CONFLICT (message_id, user_id, emoji) DO NOTHING`,
          [messageId, userId, emoji, messageType || 'canal']
        );

        // Diffuser la réaction à la room concernée
        const room = data.canalId ? `canal:${data.canalId}` : `filiere:${socket.filiere}`;
        io.to(room).emit('reaction:ajout', { messageId, userId, emoji });
        callback?.({ success: true });
      } catch (err) {
        console.error('[Socket] reaction:ajout erreur:', err.message);
        callback?.({ error: 'Erreur serveur' });
      }
    });

    // ── Événement : indicateur de frappe ─────────────────
    socket.on('user:typing', (data) => {
      const { canalId, filiereId, destinataireId } = data;
      const payload = { userId, typing: true };

      if (canalId) {
        socket.to(`canal:${canalId}`).emit('user:typing', payload);
      } else if (filiereId) {
        socket.to(`filiere:${filiereId}`).emit('user:typing', payload);
      } else if (destinataireId) {
        io.to(`user:${destinataireId}`).emit('user:typing', payload);
      }
    });

    // ── Événement : supprimer un message ─────────────────
    socket.on('message:supprimer', async (data, callback) => {
      const { messageId, canalId } = data;

      try {
        // Vérifier que c'est l'auteur ou un admin
        const { rows } = await pool.query(
          `SELECT auteur_id FROM messages WHERE id = $1`,
          [messageId]
        );
        if (!rows.length) return callback?.({ error: 'Message introuvable' });
        if (rows[0].auteur_id !== userId && socket.userRole !== 'admin') {
          return callback?.({ error: 'Non autorisé' });
        }

        await pool.query(`DELETE FROM messages WHERE id = $1`, [messageId]);

        io.to(`canal:${canalId}`).emit('message:supprimer', { messageId });
        callback?.({ success: true });
      } catch (err) {
        console.error('[Socket] message:supprimer erreur:', err.message);
        callback?.({ error: 'Erreur serveur' });
      }
    });

    // ── Déconnexion ───────────────────────────────────────
    socket.on('disconnect', () => {
      onlineUsers.delete(userId);
      io.emit('user:offline', { userId });
      console.log(`[Socket] Déconnecté : userId=${userId}`);
    });
  });
}

// Utilitaire : envoyer une notification à un utilisateur depuis n'importe quel contrôleur
function notifierUser(io, userId, event, data) {
  io.to(`user:${userId}`).emit(event, data);
}

// Pousse un événement à un utilisateur via l'instance io globale (sans req).
// Utilisé par les contrôleurs (notifications) pour la mise à jour temps réel.
function pushToUser(userId, event, data) {
  if (ioRef) ioRef.to(`user:${userId}`).emit(event, data);
}

// Utilitaire : obtenir la liste des utilisateurs en ligne
function getOnlineUsers() {
  return Array.from(onlineUsers.keys());
}

module.exports = { initSocket, notifierUser, pushToUser, getOnlineUsers };
