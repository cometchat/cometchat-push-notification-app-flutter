import 'package:cometchat/cometchat_sdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/widgets/message_composer.dart';

import 'package:flutter_pn/services/firebase_service.dart';

class HomeScreen extends StatefulWidget {
  final Function onLogout;
  final FirebaseService notificationService = FirebaseService();

  HomeScreen({
    Key? key,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? loggedInUser;

  @override
  void initState() {
    super.initState();

    widget.notificationService.init();

    CometChatService.getLoggedInUser().then((User? user) {
      setState(() {
        loggedInUser = user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  "Logged in as",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "${loggedInUser?.name}",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20.0),
                const MessageComposer(
                    sendMessage: CometChatService.sendMessage),
                Center(
                  child: MaterialButton(
                    color: Colors.amber,
                    onPressed: () async {
                      await widget.notificationService.deleteToken();
                      widget.onLogout();
                      debugPrint("Logging out");
                    },
                    child: const Text('Logout'),
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
