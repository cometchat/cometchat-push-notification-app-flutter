import 'package:flutter/material.dart';

class MessageComposer extends StatefulWidget {
  final Function sendMessage;
  const MessageComposer({Key? key, required this.sendMessage})
      : super(key: key);

  @override
  State<MessageComposer> createState() => _MessageComposerState();
}

class _MessageComposerState extends State<MessageComposer> {
  String receiverUid = "";
  String receiverType = "user";
  String textMessage = "";
  late final uidController = TextEditingController();

  final inputController = TextEditingController();
  final messageController = TextEditingController();

  void resetState() {
    setState(() {
      uidController.clear();
      messageController.clear();
      receiverUid = "";
      receiverType = "user";
      textMessage = "";
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextField(
            // clear the text field with every new message
            controller: uidController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Receiver UID",
            ),
            onChanged: (value) {
              setState(() {
                receiverUid = value;
              });
            },
          ),
          const SizedBox(
            height: 20,
          ),
          TextField(
            // Clear the text field with every new message
            controller: messageController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Message",
            ),
            onChanged: (value) {
              setState(() {
                textMessage = value;
              });
            },
          ),
          const SizedBox(
            height: 20,
          ),
          DropdownButtonFormField(
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: "Receiver Type",
            ),
            value: receiverType,
            onChanged: (value) {
              setState(() {
                receiverType = value.toString();
              });
            },
            items: const [
              DropdownMenuItem(
                value: "user",
                child: Text("User"),
              ),
              DropdownMenuItem(
                value: "group",
                child: Text("Group"),
              ),
            ],
          ),
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.sendMessage(receiverUid, textMessage, receiverType);
              resetState();
            },
            child: const Text("Send Message"),
          ),
        ],
      ),
    );
  }
}
