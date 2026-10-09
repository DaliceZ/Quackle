/*
 * File: splash_screen.dart
 * Description: UI screen displayed on app launch. Plays a bounce animation,
 * checks for a saved login session, and navigates to the appropriate screen.
 *
 * Dependencies:
 * - SharedPreferences (session persistence)
 * - ThemeDatabase (theme-aware background color)
 * - MockDatabase / User (session lookup)
 * - HomePage (authenticated destination)
 *
 * Lifecycle:
 * - Created as the initial route (/splash) by QuackApp.
 * - Disposed automatically when replaced via pushReplacement.
 *
 * Responsibilities:
 * - Plays the initial branding "bounce" animation on startup.
 * - Validates the existence of a saved user session in SharedPreferences.
 * - Determines the initial routing (Home vs. Welcome) based on session state.
 * - Pre-loads user theme preferences to ensure a seamless visual transition.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../theme/theme_data.dart';
import '../models/mock_data.dart';
import 'home.dart';

/// Entry splash screen that animates the app logo and handles session routing.
///
/// On init, a bounce animation plays while [_checkLoginState] runs in the
/// background. After a minimum 2-second delay:
/// - If a saved username is found, the user is taken directly to [HomePage].
/// - Otherwise, the user is redirected to `/welcome`.
///
/// The background color adapts to the user's last saved theme so the
/// transition feels seamless.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// The logic and animation state management for [SplashScreen].
///
/// Handles the elastic bounce animation of the logo and coordinates the
/// asynchronous lookup of [SharedPreferences] data.
///
/// Fields:
/// - [_controller]: controller managing the logo's bounce animation lifecycle
/// - [_bounceAnimation]: elastic scaling animation applied to the central logo
/// - [_backgroundColor]: theme-aware background color that updates after session check
/// - [_textColor]: theme-aware text color that updates after session check
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  Color _backgroundColor = const Color(0xFF58CC02);
  Color _textColor = Colors.white;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _bounceAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();
    _checkLoginState();
  }

  /// Checks SharedPreferences for a saved username and navigates accordingly.
  ///
  /// Side effects:
  /// - Updates [_backgroundColor] and [_textColor] to match the saved theme
  /// - Navigates to [HomePage] if a valid session is found
  /// - Navigates to `/welcome` if no session exists
  Future<void> _checkLoginState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('loggedInUser');

    User? loggedInUser;
    if (savedUsername != null) {
      try {
        loggedInUser = MockDatabase.users.firstWhere((u) => u.username == savedUsername);
        await loggedInUser.loadData();

        final theme = ThemeDatabase.getTheme(loggedInUser.currentThemeId);
        setState(() {
          _backgroundColor = theme.backgroundColor;
          _textColor = theme.textColor;
        });
      } catch (e) {
        loggedInUser = null;
      }
    }
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (loggedInUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomePage(currentUser: loggedInUser!)),
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: ScaleTransition(
          scale: _bounceAnimation,
          child: Text(
            "Quackle",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: _textColor,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
