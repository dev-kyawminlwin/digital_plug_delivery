import 'package:flutter/foundation.dart';

// Web implementation loaded via conditional import
import 'browser_notification_web.dart'
    if (dart.library.io) 'browser_notification_stub.dart';

class BrowserNotificationService {
  static Future<void> requestPermission() async {
    if (!kIsWeb) return;
    await requestNotificationPermission();
  }

  static void notify({required String title, required String body}) {
    if (!kIsWeb) return;
    showBrowserNotification(title, body);
  }
}
