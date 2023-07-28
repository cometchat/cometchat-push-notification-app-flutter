import 'package:flutter/material.dart';
import 'package:flutter_pn/screens/chat_screen.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static void navigateToChat(String text) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => ChatScreen(chatId: text)),
    );
  }
}
