import 'dart:convert';
import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_apns_x/flutter_apns/src/apns_connector.dart';
import 'package:flutter_callkit_incoming/entities/entities.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_pn/models/call_action.dart';
import 'package:flutter_pn/models/call_type.dart';
import 'package:flutter_pn/models/notification_message_type_constants.dart';
import 'package:flutter_pn/models/payload_data.dart';
import 'package:flutter_pn/services/cometchat_service.dart';

class APNSService with CometChatCallsEventsListener {


  String? id;

  @override
  void onCallEndButtonPressed() async {
    await FlutterCallkitIncoming.endCall(id!);
  }

  // This method handles displaying incoming calls, accepting, declining, or ending calls using the FlutterCallkitIncoming and CometChat.
  Future<void> displayIncomingCall(rMessage) async {

    PayloadData payloadData = PayloadData.fromJson(rMessage.data);
    String messageCategory = payloadData.type ?? "";
    if (messageCategory == 'call') {

      CallAction callAction = payloadData.callAction ?? CallAction.none;
      String uuid = payloadData.sessionId ?? "";
      final callUUID = uuid;

      String callerName = payloadData.senderName ?? "";
      CallType callType = payloadData.callType ?? CallType.none;
      if (callAction == CallAction.initiated) {

        CallKitParams callKitParams = CallKitParams(
          id: callUUID,
          nameCaller: callerName,
          appName: 'notification_new',
          type: (callType == CallType.audio) ? 0 : 1,
          textAccept: 'Accept',
          textDecline: 'Decline',
          duration: 55000,
          ios: const IOSParams(
            supportsVideo: true,
            audioSessionMode: 'default',
            audioSessionActive: true,
            audioSessionPreferredSampleRate: 44100.0,
            audioSessionPreferredIOBufferDuration: 0.005,
            ringtonePath: 'system_ringtone_default',
          ),
        );

        await FlutterCallkitIncoming.showCallkitIncoming(callKitParams);
      }
    }
  }

  init(BuildContext context) {
    final _connector = ApnsPushConnector();

    _connector.shouldPresent = (x) => Future.value(false);


    _connector.configure(
      // onLaunch gets called, when you tap on notification on a closed app
      onLaunch: (message) async {
        debugPrint('onLaunch: ${message.toString()}');
        openNotification(message,context);
      },

      // onResume gets called, when you tap on notification with app in background
      onResume: (message) async {

        openNotification(message,context);

      },
    );

    //Requesting user permissions
    _connector.requestNotificationPermissions();


    //token value get//
    _connector.token.addListener(() {

      if (_connector.token.value != null || _connector.token.value != '') {

        PNRegistry.registerPNService(_connector.token.value!,false,false);

      }
    });

    // Push Token VoIP
    FlutterCallkitIncoming.getDevicePushTokenVoIP().then(
          (voipToken) {

        if (voipToken != null || voipToken.toString().isNotEmpty) {

          PNRegistry.registerPNService(voipToken,false,true);
        }
      },
    );

    // Call event listeners

    FlutterCallkitIncoming.onEvent.listen(
          (CallEvent? callEvent) async {

        final Map<String, dynamic> body = callEvent?.body;


            PayloadData payloadData = PayloadData();
            if(body['extra']['message']!=null) {
              payloadData =
              PayloadData.fromJson(jsonDecode(body['extra']['message']));

        }
        String sessionId = payloadData.sessionId ?? '';
        id = sessionId;

        switch (callEvent?.event) {
          case Event.actionCallIncoming:
            break;
          case Event.actionCallAccept:
            CallSettingsBuilder callSettingsBuilder = (CallSettingsBuilder()
              ..enableDefaultLayout = true
            ..setAudioOnlyCall=payloadData.callType == CallType.audio);

            CometChatUIKitCalls.acceptCall(sessionId,
                onSuccess: (Call call) async {
                  call.category = MessageCategoryConstants.call;
                  CometChatCallEvents.ccCallAccepted(call);
                  await FlutterCallkitIncoming.setCallConnected(sessionId);
                  if(context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CometChatOngoingCall(
                      callSettingsBuilder: callSettingsBuilder,
                      sessionId: sessionId,
                      callWorkFlow: CallWorkFlow.defaultCalling,
                    ),
                  ),
                )
                    .then((_) async {
                  await const MethodChannel('com.cometchat.flutter_pn').invokeMethod('endCall');

                });
              }
            }, onError: (CometChatException e) {
                  debugPrint("===>>>: Error: acceptCall: ${e.message}");
                });
            break;
          case Event.actionCallDecline:
            CometChatUIKitCalls.rejectCall(
                sessionId, CallStatusConstants.rejected,
                onSuccess: (Call call) async {
                  call.category = MessageCategoryConstants.call;
                  CometChatCallEvents.ccCallRejected(call);
                  await FlutterCallkitIncoming.endCall(sessionId);
                }, onError: (e) {
              debugPrint(
                  "Unable to end call from incoming call screen ${e.message}");
            });
            break;
          case Event.actionCallEnded:
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

  // This method processes the incoming Remote message to handle user or group notifications and carries out appropriate actions such as initiating a chat or call.

  Future<void> openNotification(RemoteMessage? message, BuildContext context) async {
    if (message != null) {

      PayloadData payloadData = PayloadData.fromJson(message.data);
      if (payloadData.type == NotificationMessageTypeConstants.call) {
        displayIncomingCall(message);
      } else {
      final receiverType = payloadData.receiverType ?? "";
      User? sendUser;
      Group? sendGroup;

      String messageCategory = payloadData.type ?? "";

      if (receiverType == CometChatReceiverType.user) {
        final uid = payloadData.sender ?? "";
        await CometChat.getUser(
          uid,
          onSuccess: (user) {
            debugPrint("Got User App Background $user");
            sendUser = user;
          },
          onError: (excep) {
            debugPrint(excep.message);
          },
        );
      } else if (receiverType == CometChatReceiverType.group) {
        final guid =
            payloadData.receiver ?? "";
        await CometChat.getGroup(
          guid,
          onSuccess: (group) {
            sendGroup = group;
          },
          onError: (excep) {
            debugPrint(excep.message);
          },
        );
      }

      if (messageCategory == NotificationMessageTypeConstants.chat &&
          (receiverType == CometChatReceiverType.user && sendUser != null) ||
          (receiverType == CometChatReceiverType.group && sendGroup != null)) {
        if (context.mounted) {
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  CometChatMessages(
                    user: sendUser,
                    group: sendGroup,
                  ),
            ),);
          });
        }
      }
    }
    }
  }
}
