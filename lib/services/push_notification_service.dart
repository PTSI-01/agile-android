import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../firebase_options.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await registerCurrentToken();
    messaging.onTokenRefresh.listen(_registerToken);
  }

  static Future<void> registerCurrentToken() async {
    await _registerToken(await FirebaseMessaging.instance.getToken());
  }

  static Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final authToken = await AuthService.getToken();
    if (authToken == null || authToken.isEmpty) return;
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/notifications/device-token'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'token': token, 'platform': 'android'}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Token will be retried on the next app start or refresh.
    }
  }
}
