import 'dart:async';
import 'dart:io';
import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_pn/consts.dart';
import 'package:flutter_pn/screens/guard_screen.dart';
import 'package:flutter_pn/screens/home_screen.dart';

import 'package:flutter_pn/services/demo_meta_info.dart';

import 'get_info.dart';


class CometChatService with CallListener {

  static final CometChatService _singleton = CometChatService._internal();

  factory CometChatService() {
    return _singleton;
  }

  CometChatService._internal();

  Future<bool> isAlreadyLoggedIn() async {
    User? user = await CometChatUIKit.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    debugPrint("Logged in user: ${user?.name}");

    return user != null;
  }


   Future init() async {
    UIKitSettings uiKitSettings = (UIKitSettingsBuilder()
      ..subscriptionType = CometChatSubscriptionType.allUsers
      ..region = CometChatConstants.region
      ..autoEstablishSocketConnection = true
      ..appId = CometChatConstants.appId
      ..authKey = CometChatConstants.authKey
      ..extensions = CometChatUIKitChatExtensions.getDefaultExtensions()
      ..callingExtension = CometChatCallingExtension()
    )
        .build();

    CometChatUIKit.init(
        uiKitSettings: uiKitSettings,
        onSuccess: (String successMessage) {
          debugPrint("Cometchat ui kit Initialization success");
          try {
            CometChat.setDemoMetaInfo(jsonObject: {
              "name": DemoMetaInfoConstants.name,
              "type": DemoMetaInfoConstants.type,
              "version": info["version"] ?? DemoMetaInfoConstants.version,
              "bundle": info["bundleId"] ?? DemoMetaInfoConstants.bundle,
              "platform": DemoMetaInfoConstants.platform,
              "sampleAppFor": DemoMetaInfoConstants.sampleAppFor,
            });
          } catch (e) {
            if (kDebugMode) {
              debugPrint("setDemoMetaInfo ended with error");
            }
          }
        },
        onError: (CometChatException e) {
          debugPrint("Initialization failed with exception: ${e.message}");
        });
    debugPrint("CallingExtension enable with context called in login");
    CometChat.addCallListener("CometChatService_CallListener", this);
  }


  @Deprecated('This method is deprecated please use PNRegistry.registerPNService() instead')
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

   Future<User?> getLoggedInUser() async {
    User? user = await CometChatUIKit.getLoggedInUser(
      onSuccess: (user) => user,
      onError: (e) {
        debugPrint("Error while checking logged in user $e");
      },
    );
    return user;
  }

   Future<bool> logout(BuildContext context) async {
    showLoadingIndicatorDialog(context);
    await PNRegistry.unregisterPNService();
    CometChat.removeCallListener("CometChatService_CallListener");
    await CometChat.logout(
      onSuccess: (message) {
        if(Platform.isAndroid) {
          FirebaseMessaging.instance.deleteToken();
        }
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

   login(String uid,BuildContext context) async {
    showLoadingIndicatorDialog(context);
    User? user = await CometChatUIKit.getLoggedInUser();
    try {
      if (user != null) {
        await PNRegistry.unregisterPNService();
        await CometChatUIKit.logout(onSuccess: (_) {
        }, onError: (_) {});
      }
    } catch (_) {}
    user = await CometChatUIKit.login(uid,onSuccess: (user) {
    },);
    if(context.mounted) {
      Navigator.of(context).pop();
      if (user != null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      }
    }
  }

  @override
  void onIncomingCallCancelled(Call call) async{
    try {
      await FlutterCallkitIncoming.endCall(call.sessionId ?? "");
    } catch (e) {
      debugPrint("onIncomingCallCancelled: $e");
    }
  }
}

extension PNRegistry on CometChatService {
  static Future<String?> registerPNService(String token,bool isFcm, bool isVoip) async{
    return await CometChatNotifications.registerPushToken(
      getPushPlatform(isFcm, isVoip),
      providerId: getProviderId(isFcm),
      fcmToken: isFcm? token:null,
      deviceToken: !isFcm && !isVoip ? token : null,
      voipToken: !isFcm && isVoip ? token : null,
      onSuccess: (response) {
        debugPrint("registerPushToken:success ${response.toString()}");
      },
      onError: (e) {
        debugPrint("registerPushToken:error ${e.toString()}");
      },
    );
  }

  static Future<String?> unregisterPNService() async{
    return await CometChatNotifications.unregisterPushToken(onSuccess: (response) {
      debugPrint("Token has been unregistered successfully => ${response.toString()}");
    },
        onError: (e) {
          debugPrint("unregisterPushToken:error ${e.toString()}");
        }
    );
  }

  static String getProviderId(bool isFcm) {
    return  isFcm ? CometChatConstants.fcmProviderId: CometChatConstants.apnProviderId;
  }

  static PushPlatforms getPushPlatform(bool isFcm, bool isVoip) {
    return  isFcm ?( Platform.isAndroid ? PushPlatforms.FCM_FLUTTER_ANDROID:PushPlatforms.FCM_FLUTTER_IOS) : (isVoip? PushPlatforms.APNS_FLUTTER_VOIP:PushPlatforms.APNS_FLUTTER_DEVICE);
  }
}