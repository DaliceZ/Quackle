/*
 * File: app.dart
 * Description: Defines the root QuackApp widget, which configures the
 * global MaterialApp, theme, and named route table for the application.
 *
 * Dependencies:
 * - flutter/material.dart
 * - screens/login.dart
 * - screens/splash_screen.dart
 * - screens/welcome_screen.dart
 *
 * Responsibilities:
 * - Configures the global [MaterialApp] settings including title and debug flags.
 * - Defines the application's visual identity through [ThemeData].
 * - Orchestrates platform-aware page transition animations.
 * - Maintains the master named route table for app-wide navigation.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';

/// The root widget of the Quackle application.
///
/// Configures [MaterialApp] with the app title, global theme, platform-aware
/// page transitions, and the named route table. Navigation always starts at
/// `/splash`, which decides whether to forward to `/welcome` or directly to
/// [HomePage] based on saved login state.
class QuackApp extends StatelessWidget {
  const QuackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quackle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'DINNextRounded',
        // Smooth page transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      // Always start at splash — it handles its own timer & navigation
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
