import 'dart:async';
import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/consts.dart';
import 'package:flutter_pn/screens/guard_screen.dart';
import 'package:flutter_pn/screens/home_screen.dart';
import 'package:flutter_pn/services/firebase_service.dart';


class CometChatService {
  static Future<bool> isAlreadyLoggedIn() async {
    User? user = await CometChatUIKit.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    debugPrint("Logged in user: ${user?.name}");

    return user != null;
  }

  static Future init() async {
    UIKitSettings uiKitSettings = (UIKitSettingsBuilder()
      ..subscriptionType = CometChatSubscriptionType.allUsers
      ..region = CometChatConstants.region
      ..autoEstablishSocketConnection = true
      ..appId = CometChatConstants.appId
      ..authKey = CometChatConstants.authKey
      ..extensions = CometChatUIKitChatExtensions.getDefaultExtensions()
      ..callingExtension = CometChatCallingExtension())
        .build();

    CometChatUIKit.init(
        uiKitSettings: uiKitSettings,
        onSuccess: (String successMessage) {
          debugPrint("Cometchat ui kit Initialization success");
        },
        onError: (CometChatException e) {
          debugPrint("Initialization failed with exception: ${e.message}");
        });
    debugPrint("CallingExtension enable with context called in login");
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
    User? user = await CometChatUIKit.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    return user;
  }

  static Future<bool> logout(BuildContext context) async {
    showLoadingIndicatorDialog(context);
    await CometChat.logout(
      onSuccess: (message) {
        FirebaseService().deleteToken();
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const GuardScreen(),
        ));
      },
      onError: (error) {
        Navigator.of(context).pop();
        debugPrint("Error while logout ${error.message}");
      },
    );
    return true;
  }

  static login(String uid, context) async {
    showLoadingIndicatorDialog(context);
    User? _user = await CometChat.getLoggedInUser();
    try {
      if (_user != null) {
        await CometChatUIKit.logout(onSuccess: (_) {}, onError: (_) {});
      }
    } catch (_) {}
    _user = await CometChatUIKit.login(uid);
    Navigator.of(context).pop();
    if (_user != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeScreen()));
    }
  }
}
