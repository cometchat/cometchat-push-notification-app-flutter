import 'package:flutter/material.dart';
import 'package:flutter_pn/services/cometchat_service.dart';
import 'package:flutter_pn/widgets/login_section.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key, required}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final uidInputController = TextEditingController();

  @override
  void dispose() {
    uidInputController.dispose();
    super.dispose();
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    "assets/cometchat_logo.png",
                    height: 100,
                    width: 100,
                  ),
                  const Text(
                    "CometChat",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Push notifications Sample app",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  const Wrap(
                    children: [
                      Text(
                        "Login with one of our sample user",
                        style: TextStyle(color: Colors.black38),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20.0,
                  ),
                  SampleUsersLoginSection(
                    thatContext: context,
                  ),
                  const SizedBox(height: 20),
                  const Wrap(
                    children: [
                      Text(
                        "or else continue with another UID",
                        style: TextStyle(color: Colors.black38),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 46,
                    child: TextFormField(
                      controller: uidInputController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'UID',
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  Center(
                    child: MaterialButton(
                      color: Colors.blue[400],
                      onPressed: () async {
                        CometChatService().login(
                            uidInputController.text, context);
                      },
                      child: const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )),
        ),
      ),
    );
  }
}
