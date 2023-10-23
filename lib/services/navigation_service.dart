import 'package:flutter/material.dart';

// This class provides a global key to access the NavigatorState for navigating between screens in the app.

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}