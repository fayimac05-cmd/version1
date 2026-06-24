const ConversationModel = require('../models/conversationModel');
const MessageModel = require('../models/messageModel');
const {
  canAccessConversation,
  canWriteConversation,
} = require('../services/canalPermissions.service');
const { enrichMessages, getUserById, formatAuteur } = require('../services/user.service');
const socketService = require('../services/socket.service');

exports.getConversations = async (req, res) => {
  try {
    let conversations;
    if (['admin', 'professeur'].includes(req.user.role)) {
      conversations = await ConversationModel.findAllForAdmin();
    } else {
      conversations = await ConversationModel.findByUser(req.user.id);
    }

    res.json({ success: true, count: conversations.length, data: conversations });
  } catch (error) {
    console.error('[getConversations]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.createConversation = async (req, res) => {
  try {
    if (req.user.role !== 'etudiant') {
      return res.status(403).json({
        success: false,
        message: 'Seuls les étudiants peuvent contacter l\'administration.',
      });
    }

    const { sujet, contenu } = req.body;
    const conversation = await ConversationModel.findOrCreatePriveAdmin(req.user.id, sujet);

    if (contenu && contenu.trim()) {
      const message = await MessageModel.create({
        conversation_id: conversation.id,
        auteur_id: req.user.id,
        contenu: contenu.trim(),
        type: 'texte',
      });

      const user = await getUserById(req.user.id);
      const payload = { ...message, auteur: formatAuteur(user) };
      socketService.emitToUser(req.user.id, 'new_private_message', payload);
    }

    res.status(201).json({ success: true, data: conversation });
  } catch (error) {
    console.error('[createConversation]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getConversationMessages = async (req, res) => {
  try {
    const conversation = await ConversationModel.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ success: false, message: 'Conversation introuvable.' });
    }
    if (!canAccessConversation(req.user, conversation)) {
      return res.status(403).json({ success: false, message: 'Accès refusé.' });
    }

    const { limit = 50, offset = 0 } = req.query;
    const messages = await MessageModel.findByConversation(conversation.id, {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
    });
    const enriched = await enrichMessages(messages);

    res.json({ success: true, count: enriched.length, data: enriched });
  } catch (error) {
    console.error('[getConversationMessages]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.postConversationMessage = async (req, res) => {
  try {
    const { contenu, type = 'texte', fichier_url } = req.body;
    if (!contenu || !contenu.trim()) {
      return res.status(400).json({ success: false, message: 'Le contenu est obligatoire.' });
    }

    const conversation = await ConversationModel.findById(req.params.id);
    if (!conversation) {
      return res.status(404).json({ success: false, message: 'Conversation introuvable.' });
    }
    if (!canWriteConversation(req.user, conversation)) {
      return res.status(403).json({ success: false, message: 'Accès refusé.' });
    }

    const message = await MessageModel.create({
      conversation_id: conversation.id,
      auteur_id: req.user.id,
      contenu: contenu.trim(),
      type,
      fichier_url: fichier_url || null,
    });

    await ConversationModel.touch(conversation.id);

    const user = await getUserById(req.user.id);
    const payload = { ...message, conversation_id: conversation.id, auteur: formatAuteur(user) };

    socketService.emitToUser(conversation.etudiant_id, 'new_private_message', payload);
    if (conversation.admin_id) {
      socketService.emitToUser(conversation.admin_id, 'new_private_message', payload);
    } else {
      socketService.emitToEtablissement(1, 'admin_private_message', payload);
    }

    res.status(201).json({ success: true, data: payload });
  } catch (error) {
    console.error('[postConversationMessage]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
