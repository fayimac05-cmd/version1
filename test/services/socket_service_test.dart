import 'package:flutter_test/flutter_test.dart';
import 'package:scolarhub/services/socket_service.dart';

void main() {
  group('SocketService singleton', () {
    test('factory returns the same instance', () {
      final instance1 = SocketService();
      final instance2 = SocketService();
      expect(identical(instance1, instance2), isTrue);
    });

    test('multiple calls return same instance', () {
      final instances = List.generate(5, (_) => SocketService());
      for (final instance in instances) {
        expect(identical(instance, instances.first), isTrue);
      }
    });
  });

  group('SocketService methods do not throw', () {
    late SocketService service;

    setUp(() {
      service = SocketService();
    });

    test('connect does not throw', () {
      expect(() => service.connect('MAT001'), returnsNormally);
    });

    test('joinRoom does not throw', () {
      expect(() => service.joinRoom('room_123'), returnsNormally);
    });

    test('onCanalMessage does not throw', () {
      expect(
        () => service.onCanalMessage((data) {}),
        returnsNormally,
      );
    });

    test('sendCanalMessage does not throw', () {
      expect(
        () => service.sendCanalMessage('canal_1', {'text': 'Hello'}),
        returnsNormally,
      );
    });

    test('onPrivateMessage does not throw', () {
      expect(
        () => service.onPrivateMessage((data) {}),
        returnsNormally,
      );
    });

    test('off does not throw', () {
      expect(() => service.off('message'), returnsNormally);
    });

    test('sendPrivateMessage does not throw', () {
      expect(
        () => service.sendPrivateMessage('user_2', {'text': 'Hi'}),
        returnsNormally,
      );
    });
  });
}
