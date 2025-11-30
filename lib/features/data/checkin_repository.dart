import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: Replace with actual import of DeviceTokenRepository
// TODO: Import this from main.dart or a dedicated navigation service
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmServiceImpl(ref);
});

abstract class FcmService {
  Future<void> initializeAndRegisterToken();

  void setupForegroundMessageHandler();

  Future<void> setupTerminatedMessageInteraction();

  void setupBackgroundMessageInteraction();
}

class FcmServiceImpl implements FcmService {
  final Ref ref;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  FcmServiceImpl(this.ref);

  @override
  Future<void> initializeAndRegisterToken() async {
    print("[FcmService] Initializing and requesting permission...");
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('[FcmService] Notification permission granted.');

      String? token;
      try {
        token = await _fcm.getToken();
        if (token != null) {
          print('[FcmService] FCM Token obtained: $token');
          await _registerTokenToServer(token);
        } else {
          print('[FcmService] Error: Failed to get FCM token (token is null). FCM might still be initializing.');
        }
      } catch (e) {
        print('[FcmService] Error getting FCM token: $e');
        return;
      }

      _fcm.onTokenRefresh.listen((newToken) {
        print('[FcmService] FCM Token refreshed: $newToken');
        _registerTokenToServer(newToken);
      }, onError: (error) {
        print('[FcmService] Error listening to token refresh: $error');
      });

    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('[FcmService] Notification permission granted provisionally (iOS).');
      String? token = await _fcm.getToken();
      if (token != null) await _registerTokenToServer(token);
      _fcm.onTokenRefresh.listen(_registerTokenToServer);
    }
    else {
      print('[FcmService] Notification permission denied.');
    }
  }

  Future<void> _registerTokenToServer(String token) async {
    try {
      final String deviceType = Platform.isIOS ? 'ios' : 'android';
      print('[FcmService] Registering token with backend. Type: $deviceType');
      final repository = ref.read(deviceTokenRepositoryProvider);
      await repository.registerToken(token: token, deviceType: deviceType);

      print('[FcmService] Token successfully registered with backend.');

    } catch (e) {
      print('[FcmService] Error registering token with backend: $e');
    }
  }

  @override
  void setupForegroundMessageHandler() {
    print("[FcmService] Setting up foreground message handler.");
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('[FcmService] Received foreground message:');
      print('  Message ID: ${message.messageId}');
      print('  Message data: ${message.data}');
      if (message.notification != null) {
        print('  Message notification: ${message.notification!.title} / ${message.notification!.body}');
      }
    });
  }

  @override
  Future<void> setupTerminatedMessageInteraction() async {
    print("[FcmService] Checking for initial message (app opened from terminated state)...");
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("[FcmService] App opened via terminated notification tap.");
      _handleMessageInteraction(initialMessage);
    } else {
      print("[FcmService] No initial message found.");
    }
  }

  @override
  void setupBackgroundMessageInteraction() {
    print("[FcmService] Setting up background message opened app handler.");
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageInteraction);
  }

  void _handleMessageInteraction(RemoteMessage message) {
    print('[FcmService] Notification tapped: ${message.messageId}');
    print('  Message data for interaction: ${message.data}');

    final String? screen = message.data['screen'];
    final String? gameId = message.data['game_id'];
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (screen == 'game_detail' && gameId != null) {
        print('[FcmService] Navigating to game detail for ID: $gameId');
        // TODO: Replace with your actual GameDetailScreen and navigation method
      } else if (screen == 'some_other_screen') {
      } else {
        print('[FcmService] No specific navigation action defined in notification data.');
      }
    } else {
      print('[FcmService] Cannot handle notification interaction: Navigator context is null.');
    }
  }
}

// TODO: Replace with actual implementation using api_client.dart
final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) => DeviceTokenRepositoryStub(ref));
abstract class DeviceTokenRepository {
  Future<void> registerToken({required String token, required String deviceType});
}
class DeviceTokenRepositoryStub implements DeviceTokenRepository {
  final Ref ref;
  DeviceTokenRepositoryStub(this.ref);
  @override
  Future<void> registerToken({required String token, required String deviceType}) async {
    print("[DeviceTokenRepoStub] Simulating POST /api/v1/device-tokens with token=$token, type=$deviceType");
    await Future.delayed(const Duration(milliseconds: 400));
    print("[DeviceTokenRepoStub] Token registration simulation successful.");
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  print("[Background Handler] Handling a background message: ${message.messageId}");
  print('  Message data: ${message.data}');
  if (message.notification != null) {
    print('  Message notification: ${message.notification!.title} / ${message.notification!.body}');
  }
}