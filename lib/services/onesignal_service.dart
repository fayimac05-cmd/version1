import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'onesignal_web_bridge.dart';

class OneSignalService {
  static const String appId = '1d27fa01-4cdf-4ea7-8c47-1af912cc740b';

  /// Initialise OneSignal au lancement de l'application
  static Future<void> init() async {
    // OneSignal Flutter SDK = mobile uniquement (Android/iOS)
    // Sur le web, c'est le SDK JavaScript dans index.html qui gère tout
    if (kIsWeb) {
      debugPrint('ℹ️ [OneSignal] Web détecté — SDK JS géré dans index.html');
      return;
    }

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
    if (kIsWeb) {
      // Sur le web : SDK JS (index.html) via la passerelle
      webOneSignalLogin(externalUserId.trim());
      return;
    }
    try {
      await OneSignal.login(externalUserId.trim());
      debugPrint('👤 [OneSignal] Utilisateur connecté: $externalUserId');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du login OneSignal: $e');
    }
  }

  /// Déconnecte l'utilisateur de OneSignal lors du logout
  static Future<void> logout() async {
    if (kIsWeb) {
      webOneSignalLogout();
      return;
    }
    try {
      await OneSignal.logout();
      debugPrint('🚪 [OneSignal] Utilisateur déconnecté');
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur lors du logout OneSignal: $e');
    }
  }

  /// Demande manuellement l'autorisation d'envoyer des notifications
  static Future<bool> requestPermission() async {
    if (kIsWeb) {
      debugPrint('🔔 [OneSignal Web] Déclenchement demande de permission navigateur...');
      final granted = await requestWebNotificationPermission();
      debugPrint('🔔 [OneSignal Web] Permission retournée: $granted');
      return granted;
    }
    try {
      final granted = await OneSignal.Notifications.requestPermission(true);
      debugPrint('🔔 [OneSignal] Permission accordée: $granted');
      return granted;
    } catch (e) {
      debugPrint('❌ [OneSignal] Erreur demande permission: $e');
      return false;
    }
  }

  /// Vérifie si les notifications sont actuellement autorisées
  static bool hasPermission() {
    if (kIsWeb) {
      return isWebNotificationGranted();
    }
    try {
      return OneSignal.Notifications.permission;
    } catch (_) {
      return false;
    }
  }
}

