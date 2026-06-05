// backend/src/controllers/notifications.controller.js

const { sendNotification } = require('../services/firebase.service');
const { createClient } = require('@supabase/supabase-js');

const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// GET /api/notifications - Liste des notifications de l'utilisateur
const getNotifications = async (req, res) => {
  try {
    const userId = req.user.id;

    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({ success: true, notifications: data });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// PATCH /api/notifications/:id/lue - Marquer une notification comme lue
const marquerCommeLue = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;

    const { error } = await supabase
      .from('notifications')
      .update({ lue: true })
      .eq('id', id)
      .eq('user_id', userId);

    if (error) throw error;

    res.json({ success: true, message: 'Notification marquée comme lue' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// DELETE /api/notifications/lire-tout - Marquer toutes comme lues
const marquerToutesLues = async (req, res) => {
  try {
    const userId = req.user.id;

    const { error } = await supabase
      .from('notifications')
      .update({ lue: true })
      .eq('user_id', userId);

    if (error) throw error;

    res.json({ success: true, message: 'Toutes les notifications marquées comme lues' });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// Fonction utilitaire - Envoyer notification automatique
const envoyerNotificationAuto = async (userId, titre, corps, data = {}) => {
  try {
    // Sauvegarder en base
    await supabase.from('notifications').insert({
      user_id: userId,
      titre,
      corps,
      lue: false,
      created_at: new Date(),
    });

    // Envoyer push FCM
    await sendNotification(userId, titre, corps, data);
  } catch (error) {
    console.error('Erreur notification auto:', error);
  }
};

module.exports = {
  getNotifications,
  marquerCommeLue,
  marquerToutesLues,
  envoyerNotificationAuto,
};
