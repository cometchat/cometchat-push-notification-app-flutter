import 'dart:io';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart' as uikit;
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/services/apns_service.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/services/firebase_service.dart';
import 'package:flutter_pn/services/globals.dart';

class HomeScreen extends StatefulWidget {
  final FirebaseService notificationService = FirebaseService();
  final APNSService apnsServices = APNSService();

  HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    if (useFcm) {
      widget.notificationService.init();
      if (Platform.isAndroid) {
        widget.notificationService.checkForNavigation(context);
      }
    } else {
      widget.apnsServices.init();
    }
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      if (useFcm && Platform.isAndroid) {
        widget.notificationService.initMethod(context);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: uikit.CometChatConversationsWithMessages(
        conversationsConfiguration:
            ConversationsConfiguration(showBackButton: false, appBarOptions: [
          IconButton(
            onPressed: () async {
              await CometChatService.logout(context);
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.black,
            ),
          )
        ]),
      ),
    );
  }
}
