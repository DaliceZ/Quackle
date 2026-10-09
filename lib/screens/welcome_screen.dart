/*
 * File: welcome_screen.dart
 * Description: UI screen shown to first-time or logged-out users.
 * Displays the mascot image and a GET STARTED button that leads to the login page.
 *
 * Dependencies:
 * - Custom3DButton (components)
 *
 * Lifecycle:
 * - Created via the /welcome named route
 * - Disposed when the user navigates forward to /login
 *
 * Responsibilities:
 * - Displays the primary brand mascot and welcoming message to new users.
 * - Provides the initial navigation entry point to the authentication flow.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import '../components/custom_3d_buttton.dart';

/// Onboarding screen presenting the Quackle mascot and an entry-point button.
///
/// This is a stateless screen with no user data dependencies. It routes the
/// user to the `/login` named route when the GET STARTED button is pressed.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Image.asset('assets/images/fullbody_quackle.png', height: 350),
              const SizedBox(height: 24),
              const Text(
                'The fun way to learn!',
                style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Custom3DButton(
                text: 'GET STARTED',
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                backgroundColor: const Color(0xFF58CC02),
                shadowColor: const Color(0xFF48A901),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
