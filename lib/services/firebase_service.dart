import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_pn/consts.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/services/navigation_service.dart';
import 'package:flutter_pn/services/shared_perferences.dart';

// This method handles incoming Firebase messages in the background, specifically for displaying incoming calls on Android platform.

// 1. This has to be defined outside of any class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage rMessage) async {
  // Display the incoming call by calling the native call screen
  if (Platform.isAndroid) {
    await displayIncomingCall(rMessage);
  }
}

// This method handles displaying incoming calls, accepting, declining, or ending calls using the FlutterCallkitIncoming and CometChat.

Future<void> displayIncomingCall(RemoteMessage rMessage) async {
  dynamic ccMessage = jsonDecode(rMessage.data['message']);
  String messageCategory = ccMessage['category'];
  if (messageCategory == 'call') {
    String callAction = ccMessage['data']['action'];
    String uuid = ccMessage['data']['entities']['on']['entity']['sessionid'];
    final callUUID = uuid;
    String callerName = ccMessage['data']['entities']['by']['entity']['name'];
    String callType = ccMessage['data']['entities']['on']['entity']['type'];
    if (callAction == 'initiated') {
      CallKitParams callKitParams = CallKitParams(
        id: callUUID,
        nameCaller: callerName,
        appName: 'notification_new',
        type: (callType.toString() == "audio") ? 0 : 1,
        textAccept: 'Accept',
        textDecline: 'Decline',
        duration: 40000,
        android: const AndroidParams(
          isCustomNotification: true,
          isShowLogo: false,
          backgroundColor: '#0955fa',
          actionColor: '#4CAF50',
          incomingCallNotificationChannelName: "Incoming Call",
        ),
      );
      await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);

      FlutterCallkitIncoming.onEvent.listen(
        (CallEvent? callEvent) async {
          switch (callEvent?.event) {
            case Event.actionCallIncoming:
              SharedPreferencesClass.init();
              break;
            case Event.actionCallAccept:
              SharedPreferencesClass.setString(
                  "SessionId", callEvent?.body["id"]);
              break;
            case Event.actionCallDecline:
              CometChatUIKitCalls.rejectCall(
                  callEvent?.body["id"], CallStatusConstants.rejected,
                  onSuccess: (Call call) async {
                call.category = MessageCategoryConstants.call;
                CometChatCallEvents.ccCallRejected(call);
                await FlutterCallkitIncoming.endCall(callEvent?.body['id']);
                if (kDebugMode) {
                  debugPrint('incoming call was rejected');
                }
              }, onError: (e) {
                if (kDebugMode) {
                  debugPrint(
                      "Unable to end call from incoming call screen ${e.message}");
                }
              });
              break;
            case Event.actionCallEnded:
              await FlutterCallkitIncoming.endCall(callEvent?.body['id']);
              break;
            default:
              break;
          }
        },
        cancelOnError: false,
        onDone: () {
          if (kDebugMode) {
            debugPrint('FlutterCallkitIncoming.onEvent: done');
          }
        },
        onError: (e) {
          if (kDebugMode) {
            debugPrint('FlutterCallkitIncoming.onEvent:error ${e.toString()}');
          }
        },
      );
    }
  }
}

// This class provides functions to interact and manage Firebase Messaging services such as requesting permissions, initializing listeners, managing notifications, and handling tokens.

class FirebaseService {
  late final FirebaseMessaging _firebaseMessaging;
  late final NotificationSettings _settings;
  late final Function registerToServer;

  Future<void> init() async {
    try {
      // 2. Initialize the Firebase
      await Firebase.initializeApp();

      // 3. Get FirebaseMessaging instance
      _firebaseMessaging = FirebaseMessaging.instance;

      // 4. Request permissions
      await requestPermissions();

      // 5. Setup notification listeners
      await initListeners();

      // 6. Fetch and register FCM token
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        debugPrint('FCM Token: $token');
      }
      if (token != null) {
        await CometChatService.registerToken(token, 'fcm');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Firebase initialization error: $e');
      }
    }
  }

  // method for requesting notification permission

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
      if (kDebugMode) {
        debugPrint('Error requesting permissions: $e');
      }
    }
  }

  // This method initializes Firebase message listeners to handle background notifications, token refresh, and user interactions with messages, after checking for user permission authorization.

  Future<void> initListeners() async {
    try {
      if (_settings.authorizationStatus == AuthorizationStatus.authorized) {
        if (kDebugMode) {
          debugPrint('User granted permission');
        }

        // For handling notification when the app is in the background
        FirebaseMessaging.onBackgroundMessage(
            firebaseMessagingBackgroundHandler);

        // refresh token listener
        _firebaseMessaging.onTokenRefresh.listen((String token) async {
          if (kDebugMode) {
            debugPrint('Token refreshed: $token');
          }
          await CometChatService.registerToken(token, 'fcm');
        });

        // This line sets up a listener that triggers the 'openNotification' method when a user taps on a notification and the app opens.

        FirebaseMessaging.onMessageOpenedApp
            .listen((RemoteMessage message) async {
          openNotification(message);
        });

        FirebaseMessaging.instance
            .getInitialMessage()
            .then((RemoteMessage? message) async {
          if (message != null) {
            openNotification(message);
          }
        });
      } else {
        if (kDebugMode) {
          debugPrint('User declined or has not accepted permission');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error initializing listeners: $e.');
      }
    }
  }

  // This method processes the incoming Firebase message to handle user or group notifications and carries out appropriate actions such as initiating a chat or call.

  Future<void> openNotification(RemoteMessage? message) async {
    if (message != null) {
      String response = message.data["message"];
      dynamic parsedJson = jsonDecode(response);
      final receiverType = parsedJson['receiverType'] ?? "";
      User? sendUser;
      Group? sendGroup;
      dynamic ccMessage = jsonDecode(message.data['message']);
      String messageCategory = ccMessage['category'];
      if (receiverType == "user") {
        final uid = parsedJson['sender'];
        await CometChat.getUser(
          uid,
          onSuccess: (user) {
            debugPrint("User fetched $user");
            sendUser = user;
          },
          onError: (exception) {
            if (kDebugMode) {
              debugPrint("Error while retrieving user ${exception.message}");
            }
          },
        );
      } else if (receiverType == "group") {
        final guid =
            parsedJson['data']['entities']['receiver']['entity']['guid'];
        await CometChat.getGroup(
          guid,
          onSuccess: (group) {
            sendGroup = group;
          },
          onError: (exception) {
            if (kDebugMode) {
              debugPrint("Error while retrieving group ${exception.message}");
            }
          },
        );
      }
      if (messageCategory == 'call') {
        String callAction = ccMessage['data']['action'];
        String uuid =
            ccMessage['data']['entities']['on']['entity']['sessionid'];
        String callType = ccMessage['data']['entities']['on']['entity']['type'];
        if (callAction == 'initiated') {
          if (receiverType == "user" && sendUser != null) {
            Call call = Call(
                sessionId: uuid,
                receiverUid: sendUser?.uid ?? "",
                type: callType,
                receiverType: receiverType);
            NavigationService.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CometChatIncomingCall(
                  call: call,
                  user: sendUser,
                ),
              ),
            );
          } else if (receiverType == "group" && sendGroup != null) {
            MainVideoContainerSetting videoSettings =
                MainVideoContainerSetting();
            videoSettings.setMainVideoAspectRatio("contain");
            videoSettings.setNameLabelParams("top-left", true, "#000");
            videoSettings.setZoomButtonParams("top-right", true);
            videoSettings.setUserListButtonParams("top-left", true);
            videoSettings.setFullScreenButtonParams("top-right", true);

            CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
              ..enableDefaultLayout = true
              ..setMainVideoContainerSetting = videoSettings);

            NavigationService.navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) => CometChatOngoingCall(
                  callSettingsBuilder: callSettingsBuilder,
                  sessionId: uuid,
                ),
              ),
            );
          }
        }
      }

      // Navigating to the chat screen when messageCategory is message
      if (messageCategory == 'message' &&
              (receiverType == "user" && sendUser != null) ||
          (receiverType == "group" && sendGroup != null)) {
        NavigationService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => CometChatMessages(
              user: sendUser,
              group: sendGroup,
            ),
          ),
        );
      }
    }
  }

  // Deletes fcm token

  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error while deleting token $e');
      }
    }
  }

  // checks For navigation when app opens from terminated state when we accept call
  checkForNavigation(context) {
    final sessionID = SharedPreferencesClass.getString("SessionId");
    if (sessionID.isNotEmpty) {
      MainVideoContainerSetting videoSettings = MainVideoContainerSetting();
      videoSettings.setMainVideoAspectRatio("contain");
      videoSettings.setNameLabelParams("top-left", true, "#000");
      videoSettings.setZoomButtonParams("top-right", true);
      videoSettings.setUserListButtonParams("top-left", true);
      videoSettings.setFullScreenButtonParams("top-right", true);

      CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
        ..enableDefaultLayout = true
        ..setMainVideoContainerSetting = videoSettings);
      CometChatUIKitCalls.acceptCall(sessionID, onSuccess: (Call call) {
        call.category = MessageCategoryConstants.call;
        CometChatCallEvents.ccCallAccepted(call);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CometChatOngoingCall(
              callSettingsBuilder: callSettingsBuilder,
              sessionId: sessionID,
            ),
          ),
        );
        debugPrint('incoming call was accepted');
      }, onError: (e) {
        debugPrint("Unable to accept call from incoming call screen");
      });
    }
  }

  // checks For navigation when app opens from background state when we accept call
  initMethod(context) async {
    FlutterCallkitIncoming.onEvent.listen(
      (CallEvent? callEvent) async {
        switch (callEvent?.event) {
          case Event.actionCallIncoming:
            CometChatUIKitCalls.init(
                CometChatConstants.appId, CometChatConstants.region,
                onSuccess: (p0) {
              debugPrint("CometChatUIKitCalls initialized successfully");
            }, onError: (e) {
              debugPrint("CometChatUIKitCalls failed ${e.message}");
            });
            break;
          case Event.actionCallAccept:
            debugPrint("Incoming call has been accepted");
            MainVideoContainerSetting videoSettings =
                MainVideoContainerSetting();
            videoSettings.setMainVideoAspectRatio("contain");
            videoSettings.setNameLabelParams("top-left", true, "#000");
            videoSettings.setZoomButtonParams("top-right", true);
            videoSettings.setUserListButtonParams("top-left", true);
            videoSettings.setFullScreenButtonParams("top-right", true);

            CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
              ..enableDefaultLayout = true
              ..setMainVideoContainerSetting = videoSettings);

            CometChatUIKitCalls.acceptCall(callEvent!.body["id"],
                onSuccess: (Call call) {
              call.category = MessageCategoryConstants.call;
              CometChatCallEvents.ccCallAccepted(call);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CometChatOngoingCall(
                    callSettingsBuilder: callSettingsBuilder,
                    sessionId: callEvent.body["id"],
                  ),
                ),
              );
            }, onError: (e) {
              debugPrint(
                  "Unable to accept call from incoming call screen ${e.message}");
            });
            break;
          case Event.actionCallDecline:
            CometChatUIKitCalls.rejectCall(
                callEvent?.body["id"], CallStatusConstants.rejected,
                onSuccess: (Call call) {
              call.category = MessageCategoryConstants.call;
              CometChatCallEvents.ccCallRejected(call);
              debugPrint('incoming call was cancelled');
            }, onError: (e) {
              debugPrint(
                  "Unable to end call from incoming call screen ${e.message}");
              debugPrint(
                  "Unable to end call from incoming call screen ${e.details}");
            });
            break;
          case Event.actionCallEnded:
            await FlutterCallkitIncoming.endCall(callEvent?.body['id']);
            break;
          default:
            break;
        }
      },
      cancelOnError: false,
      onDone: () {
        debugPrint('FlutterCallkitIncoming.onEvent: done');
      },
      onError: (e) {
        debugPrint('FlutterCallkitIncoming.onEvent:error ${e.toString()}');
      },
    );
  }
}
