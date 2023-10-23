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
  late bool shouldGoToHomeScreen = false;

  @override
  void initState() {
    alreadyLoggedIn(context);
    super.initState();
  }

  alreadyLoggedIn(context) async {
    bool isLogin = await CometChatService.isAlreadyLoggedIn();
    if (isLogin) {
      final user = await CometChatUIKit.getLoggedInUser();
      if (user != null) {
        await CometChatUIKit.login(
          user.uid,
          onSuccess: (user) {
            setState(() {
              shouldGoToHomeScreen = true;
            });
          },
          onError: (excep) {
            setState(() {
              shouldGoToHomeScreen = true;
            });
          },
        );
      }
    } else {
      setState(() {
        shouldGoToHomeScreen = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return  (shouldGoToHomeScreen) ? HomeScreen() : const LoginScreen();
  }
}
