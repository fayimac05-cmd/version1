const { sendNotification } = require('../services/firebase.service');
const supabase = require('../config/supabase');

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

const envoyerNotificationAuto = async (userId, titre, corps, data = {}) => {
  try {
    await supabase.from('notifications').insert({
      user_id: userId,
      titre,
      corps,
      lue: false,
      data,
      created_at: new Date().toISOString(),
    });

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
