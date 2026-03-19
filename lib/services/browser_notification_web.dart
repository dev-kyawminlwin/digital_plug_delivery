// Web implementation using dart:js
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

Future<void> requestNotificationPermission() async {
  try {
    js.context.callMethod('eval', ["Notification.requestPermission()"]);
  } catch (_) {}
}

void showBrowserNotification(String title, String body) {
  try {
    js.context.callMethod('eval', [
      "if (Notification.permission === 'granted') { new Notification('$title', { body: '$body', icon: '/icons/Icon-192.png' }); }"
    ]);
  } catch (_) {}
}
