import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';

/// Client Socket.IO temps réel de la messagerie.
///
/// Le serveur (backend/src/socket/socketHandler.js) authentifie la connexion
/// par JWT, joint automatiquement la room personnelle `user:<id>`, la room de
/// filière `filiere:<id>` et les rooms des canaux publics `canal:<id>`.
///
/// Événements serveur → client : `message:canal`, `message:prive`,
/// `message:groupe`, `reaction:ajout`, `user:typing`.
class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  static final String _serverUrl =
      ApiService.baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  io.Socket? _socket;

  // ── Écouteurs "en attente" ────────────────────────────────────────────
  // connect() est asynchrone (attend le token, puis établit la connexion).
  // Si un écran s'abonne (onNotification, onCanalMessage...) AVANT que
  // _socket ne soit prêt, l'ancien code faisait `_socket?.on(...)` → no-op
  // silencieux, l'écouteur n'était jamais réellement attaché. On mémorise
  // maintenant chaque abonnement ici, et on les réapplique tous dès que la
  // connexion aboutit — peu importe l'ordre d'appel entre connect() et les
  // écrans qui s'abonnent.
  final Map<String, List<void Function(dynamic)>> _ecouteursEnAttente = {};

  bool get isConnected => _socket?.connected ?? false;

  void _sabonner(String event, void Function(dynamic) callback) {
    _ecouteursEnAttente.putIfAbsent(event, () => []).add(callback);
    _socket?.on(event, callback);
  }

  /// Ouvre la connexion authentifiée par le token JWT stocké.
  /// Idempotent : ne fait rien si déjà connecté.
  Future<void> connect([String? _]) async {
    if (_socket != null && _socket!.connected) return;
    final token = await ApiService.getToken();
    if (token == null || token.isEmpty) return;

    _socket?.dispose();
    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .enableForceNew()
          .build(),
    );

    // Réapplique tous les abonnements déjà demandés avant que la connexion
    // ne soit prête (voir _ecouteursEnAttente ci-dessus).
    for (final entry in _ecouteursEnAttente.entries) {
      for (final callback in entry.value) {
        _socket!.on(entry.key, callback);
      }
    }
  }

  /// Rejoint une room côté serveur (ex. 'canal:1').
  /// Les rooms usuelles sont déjà jointes automatiquement à la connexion.
  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void onCanalMessage(void Function(dynamic) callback) {
    _sabonner('message:canal', callback);
  }

  void onPrivateMessage(void Function(dynamic) callback) {
    _sabonner('message:prive', callback);
  }

  void onGroupeMessage(void Function(dynamic) callback) {
    _sabonner('message:groupe', callback);
  }

  /// Notification temps réel poussée vers la cloche de l'utilisateur.
  void onNotification(void Function(dynamic) callback) {
    _sabonner('notification', callback);
  }

  /// Envoie un message dans un canal ; le serveur le persiste et le diffuse.
  void sendCanalMessage(String canalId, Map<String, dynamic> data) {
    _socket?.emit('message:canal', {
      'canalId': int.tryParse(canalId) ?? canalId,
      'contenu': data['contenu'],
    });
  }

  /// Envoie un message privé ; le serveur le persiste et notifie le destinataire.
  void sendPrivateMessage(String destUserId, Map<String, dynamic> data) {
    _socket?.emit('message:prive', {
      'destinataireId': destUserId,
      'contenu': data['contenu'],
    });
  }

  /// Envoie un message dans le groupe de la filière.
  void sendGroupeMessage(dynamic filiereId, String contenu) {
    _socket?.emit('message:groupe', {
      'filiereId': filiereId,
      'contenu': contenu,
    });
  }

  /// Envoie un accusé de lecture pour une conversation privée.
  void sendReadReceipt(String expediteurId) {
    _socket?.emit('message:read', {
      'expediteurId': expediteurId,
    });
  }

  /// Écoute les accusés de lecture (l'expéditeur est notifié quand ses messages sont lus).
  void onMessageRead(void Function(dynamic) callback) {
    _sabonner('message:read', callback);
  }

  /// Retire les écouteurs d'un événement. Accepte les anciens noms
  /// (`new_canal_message`, …) utilisés avant la refonte.
  ///
  /// [callback] optionnel : si fourni, ne retire QUE cet écouteur précis
  /// (socket_io_client le supporte nativement). Sans lui, retire TOUS les
  /// écouteurs de l'événement — ce qui est dangereux dès que plusieurs
  /// écrans écoutent le même événement en même temps (ex. la cloche de
  /// l'accueil ET la page Notifications écoutent toutes deux 'notification'
  /// — fermer la page Notifications effaçait aussi l'écoute de l'accueil).
  /// Préférez toujours passer votre callback exact quand vous le connaissez.
  void off(String event, [void Function(dynamic)? callback]) {
    const legacy = {
      'new_canal_message': 'message:canal',
      'new_private_message': 'message:prive',
      'new_group_message': 'message:groupe',
    };
    final actualEvent = legacy[event] ?? event;
    if (callback != null) {
      _socket?.off(actualEvent, callback);
      _ecouteursEnAttente[actualEvent]?.remove(callback);
    } else {
      _socket?.off(actualEvent);
      _ecouteursEnAttente.remove(actualEvent);
    }
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}