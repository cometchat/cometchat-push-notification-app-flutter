import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:cometchat_chat_uikit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/screens/home_screen.dart';
import 'package:flutter_pn/screens/login_screen.dart';
import 'package:flutter_pn/services/cometchat_service.dart';


class GuardScreen extends StatefulWidget {
  const GuardScreen({Key? key}) : super(key: key);

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  late Future<bool> _shouldGoToHomeScreenFuture;

  @override
  void initState() {
    super.initState();
    _shouldGoToHomeScreenFuture = alreadyLoggedIn();
  }

  Future<bool> alreadyLoggedIn() async {
    await CometChatService().init();
    bool isLogin = await CometChatService().isAlreadyLoggedIn();
    bool shouldGoToHomeScreen = false;
    if (isLogin) {
      final user = await CometChatUIKit.getLoggedInUser();
      if (user != null) {
        await CometChatUIKit.login(
          user.uid,
          onSuccess: (user) {
              shouldGoToHomeScreen = true;
          },
          onError: (excep) {
              shouldGoToHomeScreen = false;
          },
        );
      }
    } else {
        shouldGoToHomeScreen = false;

    }
    return shouldGoToHomeScreen;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldGoToHomeScreenFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return  Container(
            color: Colors.white,
            child: Center(
              child: Image.asset("assets/cometchat_logo.png"),
            ),
          );
        } else if (snapshot.hasError) {
          return const LoginScreen(); // or show an error message
        } else {
          return snapshot.data == true ? HomeScreen() : const LoginScreen();
        }
      },
    );
  }
}
