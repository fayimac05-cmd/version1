import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  static const String appId = '1d27fa01-4cdf-4ea7-8c47-1af912cc740b';

  /// Initialise OneSignal au lancement de l'application
  static Future<void> init() async {
    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }

      // Initialisation avec l'App ID OneSignal
      OneSignal.initialize(appId);

      // Demander l'autorisation d'envoyer des notifications (Android 13+ et iOS)
      await OneSignal.Notifications.requestPermission(true);

      // Écouter les clics sur les notifications
      OneSignal.Notifications.addClickListener((event) {
        debugPrint('[OneSignal] Notification cliquée: ${event.notification.title}');
        debugPrint('[OneSignal] Données: ${event.notification.additionalData}');
      });

      // Écouter les notifications reçues quand l'app est au premier plan
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        debugPrint('[OneSignal] Notification reçue au premier plan: ${event.notification.title}');
        // event.preventDefault() si on voulait bloquer l'affichage système
      });

      debugPrint('✅ [OneSignal] Initialisé avec succès (App ID: $appId)');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur d\'initialisation: $e');
    }
  }

  /// Associe l'utilisateur connecté (par son matricule ou son identifiant)
  /// pour lui envoyer des notifications ciblées depuis le backend.
  static Future<void> login(String externalUserId) async {
    if (externalUserId.trim().isEmpty) return;
    try {
      await OneSignal.login(externalUserId.trim());
      debugPrint('👤 [OneSignal] Utilisateur connecté: $externalUserId');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du login OneSignal: $e');
    }
  }

  /// Déconnecte l'utilisateur de OneSignal lors du logout
  static Future<void> logout() async {
    try {
      await OneSignal.logout();
      debugPrint('🚪 [OneSignal] Utilisateur déconnecté');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du logout OneSignal: $e');
    }
  }
}

