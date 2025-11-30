import 'dart:async';
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/notification/data/device_token_repository.dart';
import '../../main.dart';


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
          print('[FcmService] Error: Failed to get FCM token (token is null).');
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
      if (message.notification != null) {
        print('  Message notification: ${message.notification!.title} / ${message.notification!.body}');
        // TODO: (任意) flutter_local_notifications を使って通知を強制的に表示する
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
    final String? gameId = message.data['game_id'];
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (gameId != null) {
        print('[FcmService] Navigating to game detail for ID: $gameId');
        // TODO: GameDetailScreen への遷移を実装
      }
    } else {
      print('[FcmService] Cannot handle notification interaction: Navigator context is null.');
    }
  }
}