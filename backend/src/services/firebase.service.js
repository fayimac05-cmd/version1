// backend/src/services/firebase.service.js

const admin = require('firebase-admin');
const { createClient } = require('@supabase/supabase-js');
const serviceAccount = require('../../config/serviceAccountKey.json');

// Initialiser Firebase Admin
if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
}

// Initialiser Supabase (clé service_role)
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

/**
 * Envoyer une notification push
 */
const sendNotification = async (userId, titre, corps, data = {}) => {
  try {
    const userToken = await getUserFCMToken(userId);

    if (!userToken) {
      console.log(`Aucun token FCM pour l'utilisateur ${userId}`);
      return null;
    }

    const message = {
      notification: { title: titre, body: corps },
      data: data,
      token: userToken,
    };

    const response = await admin.messaging().send(message);
    console.log('Notification envoyée:', response);
    return response;

  } catch (error) {
    console.error('Erreur envoi notification:', error);
    throw error;
  }
};

/**
 * Récupérer le token FCM depuis Supabase
 */
const getUserFCMToken = async (userId) => {
  const { data, error } = await supabase
    .from('users')
    .select('fcm_token')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Erreur récupération token:', error);
    return null;
  }

  return data?.fcm_token;
};

module.exports = { sendNotification };