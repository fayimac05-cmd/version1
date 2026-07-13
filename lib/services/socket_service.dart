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

  bool get isConnected => _socket?.connected ?? false;

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
  }

  /// Rejoint une room côté serveur (ex. 'canal:1').
  /// Les rooms usuelles sont déjà jointes automatiquement à la connexion.
  void joinRoom(String roomId) {
    _socket?.emit('join_room', {'roomId': roomId});
  }

  void onCanalMessage(void Function(dynamic) callback) {
    _socket?.on('message:canal', callback);
  }

  void onPrivateMessage(void Function(dynamic) callback) {
    _socket?.on('message:prive', callback);
  }

  void onGroupeMessage(void Function(dynamic) callback) {
    _socket?.on('message:groupe', callback);
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

  /// Retire les écouteurs d'un événement. Accepte les anciens noms
  /// (`new_canal_message`, …) utilisés avant la refonte.
  void off(String event) {
    const legacy = {
      'new_canal_message': 'message:canal',
      'new_private_message': 'message:prive',
      'new_group_message': 'message:groupe',
    };
    _socket?.off(legacy[event] ?? event);
  }

  void disconnect() {
    _socket?.dispose();
    _socket = null;
  }
}
