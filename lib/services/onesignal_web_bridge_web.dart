// Implémentation réelle pour Flutter Web via dart:js_interop
import 'dart:js_interop';

@JS('demanderPermissionOneSignal')
external JSPromise<JSBoolean> _demanderPermissionOneSignal();

@JS('estPermissionOneSignalAccordee')
external JSBoolean _estPermissionOneSignalAccordee();

Future<bool> requestWebNotificationPermission() async {
  try {
    final promise = _demanderPermissionOneSignal();
    final jsBool = await promise.toDart;
    return jsBool.toDart;
  } catch (e) {
    return false;
  }
}

bool isWebNotificationGranted() {
  try {
    return _estPermissionOneSignalAccordee().toDart;
  } catch (_) {
    return false;
  }
}

