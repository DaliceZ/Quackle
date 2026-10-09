/*
 * File: main.dart
 * Description: Application entry point.
 * Initializes the Flutter framework, locks orientation to portrait,
 * and launches the root QuackApp widget.
 *
 * Notes:
 * - Contains global app configuration (orientation lock).
 * - Should remain lightweight.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]).then((_) {
    runApp(const QuackApp());
  });
}
