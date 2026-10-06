import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../firebase_options.dart';
import '../screens/purchase_page.dart';
import '../screens/bongkaran_page.dart';
import 'auth_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  static final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onMessage.listen(_showForegroundBanner);
    FirebaseMessaging.onMessageOpenedApp.listen(_openMessage);
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future<void>.delayed(const Duration(milliseconds: 700), () {
        _openMessage(initialMessage);
      });
    }
    await registerCurrentToken();
    messaging.onTokenRefresh.listen(_registerToken);
  }

  static void _showForegroundBanner(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notifikasi baru';
    final body = message.notification?.body ?? 'Ada pembaruan pada transaksi.';
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentMaterialBanner()
      ..showMaterialBanner(
        MaterialBanner(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFE5EFDF),
            child: Icon(Icons.eco_rounded, color: Color(0xFF1F7A2E)),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                messenger.hideCurrentMaterialBanner();
                _openMessage(message);
              },
              child: const Text('Buka'),
            ),
            TextButton(
              onPressed: messenger.hideCurrentMaterialBanner,
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
  }

  static void _openMessage(RemoteMessage message) {
    final type = message.data['type']?.toString();
    final id = message.data['po_id']?.toString();
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    if (type == 'pembelian' && id != null && id.isNotEmpty) {
      navigator.push(MaterialPageRoute(
        builder: (_) => PurchasePage(initialPurchaseId: id),
      ));
    } else if (type == 'bongkaran') {
      navigator.push(MaterialPageRoute(builder: (_) => const BongkaranPage()));
    }
  }

  static Future<void> registerCurrentToken() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      String? token;
      try {
        token = await FirebaseMessaging.instance.getToken();
      } catch (error) {
        debugPrint('FCM: gagal mengambil token (percobaan ${attempt + 1}): $error');
      }
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
        return;
      }
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    debugPrint('FCM: token belum tersedia setelah 3 percobaan.');
  }

  static Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    final authToken = await AuthService.getToken();
    if (authToken == null || authToken.isEmpty) return;
    try {
      final headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      };
      final body = jsonEncode({'token': token, 'platform': 'android'});
      final endpoints = <String>[
        '${ApiConfig.baseUrl}/v1/notifications/device-token',
        '${ApiConfig.baseUrl}/notifications/device-token',
      ];
      for (final endpoint in endpoints) {
        final response = await http.post(Uri.parse(endpoint), headers: headers, body: body)
            .timeout(const Duration(seconds: 15));
        debugPrint('FCM: register $endpoint HTTP ${response.statusCode}: ${response.body}');
        if (response.statusCode != 404) return;
      }
    } catch (error) {
      debugPrint('FCM: gagal register token: $error');
    }
  }
}
