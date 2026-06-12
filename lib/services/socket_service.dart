import 'dart:async';

class SocketService {
  static final SocketService _instance = SocketService._internal();

  factory SocketService() {
    return _instance;
  }

  SocketService._internal();

  void connect(String matricule) {
    // Mock connection
  }

  void joinRoom(String roomId) {
    // Mock join room
  }

  void onCanalMessage(void Function(dynamic) callback) {
    // Mock callback
  }

  void sendCanalMessage(String canalId, Map<String, dynamic> data) {
    // Mock send message
  }

  void onPrivateMessage(void Function(dynamic) callback) {
    // Mock callback
  }

  void off(String event) {
    // Mock off
  }

  void sendPrivateMessage(String dest, Map<String, dynamic> data) {
    // Mock send message
  }
}
