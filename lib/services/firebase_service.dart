import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/services/navigation_service.dart';
import 'package:flutter_pn/firebase_options.dart';

// 1. This has to be defined outside of any class
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage rMessage) async {}

class FirebaseService {
  late final FirebaseMessaging _firebaseMessaging;
  late final NotificationSettings _settings;
  late final Function registerToServer;

  Future<void> init() async {
    try {
      // 2. Initialize the Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // 3. Get FirebaseMessaging instance
      _firebaseMessaging = FirebaseMessaging.instance;

      // 4. Request permissions
      await requestPermissions();

      // 5. Setup notification listerners
      await initListeners();

      // 6. Fetch and register FCM token
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) {
        await CometChatService.registerToken(token, 'fcm');
      }
    } catch (e) {
      debugPrint('Firebase initialization error: $e');
    }
  }

  Future<void> requestPermissions() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      _settings = settings;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
    }
  }

  Future<void> initListeners() async {
    try {
      if (_settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted permission');

        // For handling notification when the app is in the background
        FirebaseMessaging.onBackgroundMessage(
            _firebaseMessagingBackgroundHandler);

        _firebaseMessaging.onTokenRefresh.listen((String token) async {
          debugPrint('Token refreshed: $token');
          await CometChatService.registerToken(token, 'fcm');
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          NavigationService.navigateToChat('Background state tap');
        });

        FirebaseMessaging.instance
            .getInitialMessage()
            .then((RemoteMessage? message) {
          if (message != null) {
            NavigationService.navigateToChat('Terminated state tap');
          }
        });
      } else {
        debugPrint('User declined or has not accepted permission');
      }
    } catch (e) {
      debugPrint('Error initializing listeners: $e');
    }
  }

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      debugPrint('Error while deleting token $e');
    }
  }
}
