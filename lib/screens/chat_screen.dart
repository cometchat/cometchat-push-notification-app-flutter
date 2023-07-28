import 'package:flutter/material.dart';

class ChatScreen extends StatelessWidget {
  final String chatId;
  const ChatScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // safeArea is used to avoid the notch and camera cutout
      // on the screen

      appBar: AppBar(
        title: const Text('Chat Screen'),
      ),
      body: SafeArea(
        child: Center(
          child: Text(chatId),
        ),
      ),
    );
  }
}
