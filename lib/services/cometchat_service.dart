import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cometchat/cometchat_sdk.dart';
import 'package:flutter_pn/consts.dart';
import 'package:flutter/foundation.dart';

class CometChatInitVerdict {
  bool isInitialized = false;
  bool isUserLoggedIn = false;

  CometChatInitVerdict(
      {required this.isInitialized, required this.isUserLoggedIn});

  @override
  String toString() {
    return 'CometChatInitVerdict{isInitialized: $isInitialized, isUserLoggedIn: $isUserLoggedIn}';
  }
}

class CometChatService {
  static late final String appId;
  static late final String region;
  static late final String authKey;
  static late final AppSettings appSettings;

  CometChatService() {
    if (CometChatConstants.appId == '' ||
        CometChatConstants.region == '' ||
        CometChatConstants.authKey == '') {
      debugPrint('No entries in consts.dart file');
      throw Error();
    } else {
      appId = CometChatConstants.appId;
      region = CometChatConstants.region;
      authKey = CometChatConstants.authKey;

      appSettings = (AppSettingsBuilder()
            ..subscriptionType = CometChatSubscriptionType.allUsers
            ..region = CometChatConstants.region
            ..autoEstablishSocketConnection = true)
          .build();
    }
  }

  static Future<bool> isAlreadyLoggedIn() async {
    User? user = await CometChat.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    debugPrint("Logged in user: ${user?.name}");

    return user != null;
  }

  static Future<CometChatInitVerdict> init() async {
    debugPrint('1. Starting CometChat initialization...');
    Completer<CometChatInitVerdict> c = Completer();

    CometChat.init(appId, appSettings, onSuccess: (String success) async {
      debugPrint("2. Init successful!");
      bool value = await isAlreadyLoggedIn();
      debugPrint('3. Checked for logged in user: $value');
      CometChatInitVerdict i =
          CometChatInitVerdict(isInitialized: true, isUserLoggedIn: value);
      c.complete(i);
    }, onError: (CometChatException e) {
      debugPrint("2. Init failed with exception: ${e.message}");
      CometChatInitVerdict i =
          CometChatInitVerdict(isInitialized: false, isUserLoggedIn: false);
      c.complete(i);
    });

    return c.future;
  }

  static Future<void> registerToken(String token, String type) async {
    final Map<String, dynamic> body = type == 'apns'
        ? {"apnsToken": token}
        : type == 'voip'
            ? {"voipToken": token}
            : {'fcmToken': token};

    CometChat.callExtension('push-notification', 'POST', '/v2/tokens', body,
        onSuccess: (message) {
      debugPrint("Registered successfully: ${message.toString()}");
      return true;
    }, onError: (CometChatException e) {
      debugPrint("Registration failed with exception: ${e.message}");
      return false;
    });
  }

  static Future<User?> getLoggedInUser() async {
    User? user = await CometChat.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    return user;
  }

  static Future<bool> sendMessage(
      String receiverUid, String textMessage, String receiverType) async {
    TextMessage message = TextMessage(
      type: 'text',
      receiverUid: receiverUid,
      text: textMessage,
      receiverType: receiverType,
    );

    TextMessage? m = await CometChat.sendMessage(
      message,
      onSuccess: (TextMessage message) {
        debugPrint("Message sent successfully: ${message.toString()}");
      },
      onError: (CometChatException e) {
        debugPrint("Message sending failed with exception: ${e.message}");
      },
    );
    return m != null;
  }

  static Future<bool> logout() async {
    await CometChat.logout(
      onSuccess: (message) {
        debugPrint("LOGOUT SUCCESS $message");
      },
      onError: (error) {
        debugPrint("LOGOUT ERRORED $error");
      },
    );
    return true;
  }

  static Future<bool> login(String uid) async {
    bool isLoggedIn = await isAlreadyLoggedIn();

    if (!isLoggedIn) {
      debugPrint("Login attempted $uid");

      User? user = await CometChat.login(
        uid,
        authKey,
        onSuccess: (User user) {
          return user;
        },
        onError: (CometChatException e) {
          debugPrint("LOGIN ERRORED $e");
        },
      );
      return user != null;
    }
    debugPrint("Login skipped");
    return true;
  }
}
