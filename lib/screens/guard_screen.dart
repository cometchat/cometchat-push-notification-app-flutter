import 'package:flutter/material.dart';
import 'package:flutter_pn/screens/home_screen.dart';
import 'package:flutter_pn/screens/login_screen.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/services/navigation_service.dart';

class GuardScreen extends StatefulWidget {
  const GuardScreen({Key? key}) : super(key: key);

  @override
  State<GuardScreen> createState() => _GuardScreenState();
}

class _GuardScreenState extends State<GuardScreen> {
  late bool shouldGoToHomeScreen = false;
  final CometChatService ccService = CometChatService();

  onLogout() {
    CometChatService.logout().then(
      (value) {
        setState(() {
          shouldGoToHomeScreen = false;
        });
      },
    );
  }

  onLogin(String uid) {
    CometChatService.login(uid).then((isLoginSuccess) {
      if (isLoginSuccess) {
        setState(() {
          shouldGoToHomeScreen = true;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    CometChatService.init().then(
      (initVerdict) {
        if (initVerdict.isInitialized && initVerdict.isUserLoggedIn) {
          setState(() {
            shouldGoToHomeScreen = true;
          });
        } else {
          setState(() {
            shouldGoToHomeScreen = false;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      home: shouldGoToHomeScreen
          ? HomeScreen(
              onLogout: onLogout,
            )
          : LoginScreen(
              onLogin: onLogin,
            ),
      title: 'CometChat Push notifications sample app',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xffeeeeee),
        primarySwatch: Colors.blue,
      ),
    );
  }
}
