const CanalModel = require('../models/canalModel');
const MessageModel = require('../models/messageModel');
const { canReadCanal, canWriteCanal } = require('../services/canalPermissions.service');
const { enrichMessages, getUserById, formatAuteur } = require('../services/user.service');
const socketService = require('../services/socket.service');

async function resolveUser(req) {
  return getUserById(req.user.id);
}

exports.getCanaux = async (req, res) => {
  try {
    const user = await resolveUser(req);
    const etablissementId = user?.etablissement_id || req.query.etablissement_id || 1;

    const canaux = await CanalModel.findAll({ etablissement_id: etablissementId });
    const accessible = canaux.filter((c) => canReadCanal(user, c));

    res.json({ success: true, count: accessible.length, data: accessible });
  } catch (error) {
    console.error('[getCanaux]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getCanalById = async (req, res) => {
  try {
    const user = await resolveUser(req);
    const canal = await CanalModel.findById(req.params.id);
    if (!canal) return res.status(404).json({ success: false, message: 'Canal introuvable.' });
    if (!canReadCanal(user, canal)) {
      return res.status(403).json({ success: false, message: 'Accès refusé à ce canal.' });
    }

    const canWrite = canWriteCanal(user, canal);
    res.json({ success: true, data: { ...canal, canWrite } });
  } catch (error) {
    console.error('[getCanalById]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.getCanalMessages = async (req, res) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;
    const { limit = 50, offset = 0 } = req.query;

    const canal = await CanalModel.findById(id);
    if (!canal) return res.status(404).json({ success: false, message: 'Canal introuvable.' });
    if (!canReadCanal(user, canal)) {
      return res.status(403).json({ success: false, message: 'Accès refusé.' });
    }

    const messages = await MessageModel.findByCanal(id, {
      limit: parseInt(limit, 10),
      offset: parseInt(offset, 10),
    });
    const enriched = await enrichMessages(messages);

    res.json({
      success: true,
      canal: { id: canal.id, nom: canal.nom, type: canal.type },
      count: enriched.length,
      data: enriched,
    });
  } catch (error) {
    console.error('[getCanalMessages]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

exports.postCanalMessage = async (req, res) => {
  try {
    const user = await resolveUser(req);
    const { id } = req.params;
    const { contenu, type = 'texte', fichier_url } = req.body;

    if (!contenu || !contenu.trim()) {
      return res.status(400).json({ success: false, message: 'Le contenu est obligatoire.' });
    }

    const canal = await CanalModel.findById(id);
    if (!canal) return res.status(404).json({ success: false, message: 'Canal introuvable.' });

    if (!canWriteCanal(user, canal)) {
      return res.status(403).json({
        success: false,
        message: 'Vous n\'avez pas le droit de publier dans ce canal.',
      });
    }

    const message = await MessageModel.create({
      canal_id: id,
      auteur_id: req.user.id,
      contenu: contenu.trim(),
      type,
      fichier_url: fichier_url || null,
    });

    const payload = {
      ...message,
      canal_id: id,
      canal_type: canal.type,
      auteur: formatAuteur(user),
    };

    socketService.emitToCanal(id, 'new_canal_message', payload);

    if (canal.etablissement_id) {
      socketService.emitToEtablissement(canal.etablissement_id, 'canal_activity', {
        canalId: id,
        canalType: canal.type,
        preview: contenu.substring(0, 100),
      });
    }

    res.status(201).json({ success: true, message: 'Message publié.', data: payload });
  } catch (error) {
    console.error('[postCanalMessage]', error);
    res.status(500).json({ success: false, message: error.message });
  }
};
