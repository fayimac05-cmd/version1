// backend/src/services/firebase.service.js

const { createClient } = require('@supabase/supabase-js');

let admin;
let hasFirebase = false;

try {
  admin = require('firebase-admin');
  const serviceAccount = require('../../config/serviceAccountKey.json');
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
  }
  hasFirebase = true;
  console.log('✅ Firebase Admin configuré avec succès');
} catch (error) {
  console.warn("⚠️ [Warning] Firebase Admin non configuré ou 'serviceAccountKey.json' introuvable. Les notifications push seront simulées.");
}

// Initialiser Supabase (clé service_role) si configuré
let supabase = null;
if (process.env.SUPABASE_URL && process.env.SUPABASE_SERVICE_KEY) {
  supabase = createClient(process.env.SUPABASE_URL, process.env.SUPABASE_SERVICE_KEY);
}

/**
 * Envoyer une notification push
 */
const sendNotification = async (userId, titre, corps, data = {}) => {
  try {
    if (!hasFirebase) {
      console.log(`[Notification simulée] Envoi à ${userId} : "${titre}" - "${corps}"`);
      return { success: true, simulated: true };
    }

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
  if (!supabase) return null;
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