import 'package:cometchat_calls_uikit/cometchat_calls_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pn/screens/guard_screen.dart';
import 'package:flutter_pn/services/get_info.dart';
import 'package:flutter_pn/services/shared_perferences.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    initServices();
    super.initState();
  }

  initServices() async {
    info = await GetInfo.initAppInfo();
    SharedPreferencesClass.init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
       title: 'Push Notifications Sample App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: GuardScreen(
        key: CallNavigationContext.navigatorKey,
      ),
    );
  }
}
