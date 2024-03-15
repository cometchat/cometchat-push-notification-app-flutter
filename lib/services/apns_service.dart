// To Use the apns services please un-comment the #  flutter_apns_x: ^0.0.1 #  flutter_apns_only: any in pubspec yaml

// import 'dart:convert';
// import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
// import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
// import 'package:flutter/material.dart';
// // import 'package:flutter_apns_x/flutter_apns/apns.dart';
// // import 'package:flutter_apns_x/flutter_apns/flutter_apns_x.dart';
// import 'package:flutter_callkit_incoming/entities/entities.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:flutter_pn/services/cometchat_service.dart';
// import 'package:flutter_pn/services/navigation_service.dart';
//
// class APNSService with CometChatCallsEventsListener {
//   // final _connector = createPushConnector();
//
//   String? id;
//
//   @override
//   void onCallEndButtonPressed() async {
//     await FlutterCallkitIncoming.endCall(id!);
//   }
//
//   // This method handles displaying incoming calls, accepting, declining, or ending calls using the FlutterCallkitIncoming and CometChat.
//   Future<void> displayIncomingCall(rMessage) async {
//     dynamic ccMessage = jsonDecode(rMessage.data['message']);
//     String messageCategory = ccMessage['category'];
//     if (messageCategory == 'call') {
//       String callAction = ccMessage['data']['action'];
//       String uuid = ccMessage['data']['entities']['on']['entity']['sessionid'];
//       final callUUID = uuid;
//       String callerName = ccMessage['data']['entities']['by']['entity']['name'];
//       String callType = ccMessage['data']['entities']['on']['entity']['type'];
//       if (callAction == 'initiated') {
//         CallKitParams callKitParams = CallKitParams(
//           id: callUUID,
//           nameCaller: callerName,
//           appName: 'notification_new',
//           type: (callType.toString() == "audio") ? 0 : 1,
//           textAccept: 'Accept',
//           textDecline: 'Decline',
//           duration: 55000,
//           ios: const IOSParams(
//             iconName: 'CallKitLogo',
//             supportsVideo: true,
//             audioSessionMode: 'default',
//             audioSessionActive: true,
//             audioSessionPreferredSampleRate: 44100.0,
//             audioSessionPreferredIOBufferDuration: 0.005,
//             ringtonePath: 'system_ringtone_default',
//           ),
//         );
//         await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
//       }
//     }
//   }
//
//   init() {
//     _connector.configure(
//       onBackgroundMessage: (message) async {
//         debugPrint('onBackgroundMessage: ${message.toString()}');
//         displayIncomingCall(message);
//       },
//
//       // onMessage gets called, when a new notification is received
//       onMessage: (message) async {
//         debugPrint('onMessage: ${message.toString()}');
//       },
//
//       // onLaunch gets called, when you tap on notification on a closed app
//       onLaunch: (message) async {
//         debugPrint('onLaunch: ${message.toString()}');
//         openNotification(message);
//       },
//
//       // onResume gets called, when you tap on notification with app in background
//       onResume: (message) async {
//         debugPrint('onResume: ${message.toString()}');
//         openNotification(message);
//       },
//     );
//
//     //Requesting user permissions
//     _connector.requestNotificationPermissions();
//
//     //token value get//
//     _connector.token.addListener(() {
//       debugPrint('Token ${_connector.token.value}');
//       if (_connector.token.value != null || _connector.token.value != '') {
//         CometChatService.registerToken(_connector.token.value ?? "", 'apns');
//       }
//     });
//
//     // Push Token VoIP
//     FlutterCallkitIncoming.getDevicePushTokenVoIP().then(
//           (voipToken) {
//         debugPrint('VoIP token: $voipToken');
//         if (voipToken != null || voipToken.toString().isNotEmpty) {
//           CometChatService.registerToken(voipToken, 'voip');
//         }
//       },
//     );
//
//     // Call event listeners
//
//     FlutterCallkitIncoming.onEvent.listen(
//           (CallEvent? callEvent) async {
//         final Map<String, dynamic> body = callEvent?.body;
//         final Map<dynamic, dynamic>? extra = body['extra'];
//         final String sessionId = extra != null
//             ? jsonDecode(extra['message'])['data']['entities']['on']['entity']
//         ['sessionid']
//             : '';
//         id = sessionId;
//
//         switch (callEvent?.event) {
//           case Event.actionCallIncoming:
//             break;
//           case Event.actionCallAccept:
//             MainVideoContainerSetting videoSettings =
//             MainVideoContainerSetting();
//             videoSettings.setMainVideoAspectRatio("contain");
//             videoSettings.setNameLabelParams("top-left", true, "#000");
//             videoSettings.setZoomButtonParams("top-right", true);
//             videoSettings.setUserListButtonParams("top-left", true);
//             videoSettings.setFullScreenButtonParams("top-right", true);
//
//             CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
//               ..enableDefaultLayout = true
//               ..setMainVideoContainerSetting = videoSettings);
//
//             CometChatUIKitCalls.acceptCall(sessionId,
//                 onSuccess: (Call call) async {
//                   call.category = MessageCategoryConstants.call;
//                   CometChatCallEvents.ccCallAccepted(call);
//                   NavigationService.navigatorKey.currentState
//                       ?.push(
//                     MaterialPageRoute(
//                       builder: (context) => CometChatOngoingCall(
//                         callSettingsBuilder: callSettingsBuilder,
//                         sessionId: sessionId,
//                       ),
//                     ),
//                   )
//                       .then((_) async =>
//                   await FlutterCallkitIncoming.endCall(sessionId));
//                 }, onError: (CometChatException e) {
//                   debugPrint("===>>>: Error: acceptCall: ${e.message}");
//                 });
//             break;
//           case Event.actionCallDecline:
//             CometChatUIKitCalls.rejectCall(
//                 sessionId, CallStatusConstants.rejected,
//                 onSuccess: (Call call) async {
//                   call.category = MessageCategoryConstants.call;
//                   CometChatCallEvents.ccCallRejected(call);
//                   await FlutterCallkitIncoming.endCall(sessionId);
//                 }, onError: (e) {
//               debugPrint(
//                   "Unable to end call from incoming call screen ${e.message}");
//             });
//             break;
//           case Event.actionCallEnded:
//             await FlutterCallkitIncoming.endCall(sessionId);
//             break;
//           default:
//             break;
//         }
//       },
//       cancelOnError: false,
//       onDone: () {
//         debugPrint('FlutterCallkitIncoming.onEvent: done');
//       },
//       onError: (e) {
//         debugPrint('FlutterCallkitIncoming.onEvent:error ${e.toString()}');
//       },
//     );
//   }
//
//   // This method processes the incoming Remote message to handle user or group notifications and carries out appropriate actions such as initiating a chat or call.
//
//   Future<void> openNotification(RemoteMessage? message) async {
//     if (message != null) {
//       String response = message.data["message"];
//       dynamic parsedJson = jsonDecode(response);
//       final receiverType = parsedJson['receiverType'] ?? "";
//       User? sendUser;
//       Group? sendGroup;
//       dynamic ccMessage = jsonDecode(message.data['message']);
//       String messageCategory = ccMessage['category'];
//       debugPrint("Message Type : $messageCategory");
//       if (receiverType == "user") {
//         final uid = parsedJson['sender'];
//         await CometChat.getUser(
//           uid,
//           onSuccess: (user) {
//             debugPrint("Got User App Background $user");
//             sendUser = user;
//           },
//           onError: (excep) {
//             debugPrint(excep.message);
//           },
//         );
//       } else if (receiverType == "group") {
//         final guid =
//         parsedJson['data']['entities']['receiver']['entity']['guid'];
//         await CometChat.getGroup(
//           guid,
//           onSuccess: (group) {
//             sendGroup = group;
//           },
//           onError: (excep) {
//             debugPrint(excep.message);
//           },
//         );
//       }
//
//       if (messageCategory == 'message' &&
//           (receiverType == "user" && sendUser != null) ||
//           (receiverType == "group" && sendGroup != null)) {
//         NavigationService.navigatorKey.currentState?.push(
//           MaterialPageRoute(
//             builder: (context) => CometChatMessages(
//               user: sendUser,
//               group: sendGroup,
//             ),
//           ),
//         );
//       }
//     }
//   }
// }
