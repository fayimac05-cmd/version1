/**
 * Contrôleur pour les uploads de fichiers (copies d'examen, photos de
 * profil/couverture, etc.)
 */

const pool = require('../config/db');

// POST /api/upload/copie - Upload une copie d'examen
exports.uploadExamCopy = async (req, res) => {
  try {
    if (!req.uploadedFileUrl) {
      return res.status(400).json({
        success: false,
        message: 'Aucun fichier uploadé.',
      });
    }

    res.status(200).json({
      success: true,
      message: 'Fichier uploadé avec succès.',
      url: req.uploadedFileUrl,
    });
  } catch (error) {
    console.error('[uploadExamCopy] Erreur :', error);
    res.status(500).json({
      success: false,
      message: 'Erreur lors de l\'upload du fichier.',
      error: error.message,
    });
  }
};

// POST /api/upload/message — pièce jointe de message (document, photo,
// vidéo ou audio) dans une conversation (canal, groupe filière, privé).
exports.uploadMessageFile = async (req, res) => {
  try {
    if (!req.uploadedFileUrl) {
      return res.status(400).json({ success: false, message: 'Aucun fichier uploadé.' });
    }
    res.status(200).json({ success: true, url: req.uploadedFileUrl });
  } catch (error) {
    console.error('[uploadMessageFile] Erreur :', error);
    res.status(500).json({ success: false, message: 'Erreur lors de l\'upload du fichier.' });
  }
};

// ── Photo de profil / couverture ──────────────────────────────────────────
// ✅ NOUVEAU — remplace l'ancien système (ProfileMediaService côté Flutter)
// qui passait directement par le client Supabase, avec RLS bloquant
// silencieusement les écritures, un nom de table erroné ('profs' au lieu de
// 'professeurs'), et une clé de cache basée sur le matricule — vide pour les
// professeurs (plus de matricule généré depuis la refonte du login), ce qui
// faisait partager LA MÊME photo à tous les professeurs sans matricule.
// Ici : authentification JWT classique (req.user.id, toujours présent et
// stable, quel que soit le rôle), persistance directe dans users.photo_url /
// users.cover_url — la même table utilisée partout ailleurs dans l'app.

// POST /api/upload/photo-profil
exports.uploadPhotoProfil = async (req, res) => {
  try {
    if (!req.uploadedFileUrl) {
      return res.status(400).json({ success: false, message: 'Aucun fichier uploadé.' });
    }
    await pool.query('UPDATE users SET photo_url = $1 WHERE id = $2', [req.uploadedFileUrl, req.user.id]);
    res.status(200).json({ success: true, url: req.uploadedFileUrl });
  } catch (error) {
    console.error('[uploadPhotoProfil] Erreur :', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour de la photo de profil.' });
  }
};

// POST /api/upload/photo-couverture
exports.uploadPhotoCouverture = async (req, res) => {
  try {
    if (!req.uploadedFileUrl) {
      return res.status(400).json({ success: false, message: 'Aucun fichier uploadé.' });
    }
    await pool.query('UPDATE users SET cover_url = $1 WHERE id = $2', [req.uploadedFileUrl, req.user.id]);
    res.status(200).json({ success: true, url: req.uploadedFileUrl });
  } catch (error) {
    console.error('[uploadPhotoCouverture] Erreur :', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la mise à jour de la photo de couverture.' });
  }
};

// DELETE /api/upload/photo-profil
exports.deletePhotoProfil = async (req, res) => {
  try {
    await pool.query('UPDATE users SET photo_url = NULL WHERE id = $1', [req.user.id]);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('[deletePhotoProfil] Erreur :', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression de la photo de profil.' });
  }
};

// DELETE /api/upload/photo-couverture
exports.deletePhotoCouverture = async (req, res) => {
  try {
    await pool.query('UPDATE users SET cover_url = NULL WHERE id = $1', [req.user.id]);
    res.status(200).json({ success: true });
  } catch (error) {
    console.error('[deletePhotoCouverture] Erreur :', error);
    res.status(500).json({ success: false, message: 'Erreur lors de la suppression de la photo de couverture.' });
  }
};