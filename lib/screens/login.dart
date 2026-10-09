/*
 * File: login.dart
 * Description: UI screen for user authentication. Validates input, calls
 * MockDatabase.login(), persists the session, and navigates to HomePage.
 *
 * Dependencies:
 * - MockDatabase / User (mock_data.dart)
 * - SharedPreferences (session persistence)
 * - Custom3DButton (components)
 * - HomePage (authenticated destination)
 *
 * Lifecycle:
 * - Created via the /login named route.
 * - Disposed when the user is authenticated and replaced by HomePage.
 *
 * Responsibilities:
 * - Captures and validates user credentials through a secure form interface.
 * - Interfaces with the MockDatabase to authenticate users.
 * - Establishes persistent sessions by storing user tokens in local storage.
 * - Provides visual feedback for authentication progress and error states.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import '../components/custom_3d_buttton.dart';
import '../models/mock_data.dart';
import 'home.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Login screen that authenticates users against [MockDatabase].
///
/// Validates the username and password fields, shows a loading indicator
/// during the async login call, persists the username to [SharedPreferences]
/// on success, and displays an error SnackBar on failure.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

/// The logic and state management for [LoginPage].
///
/// Handles form validation, asynchronous authentication calls, and
/// management of persistent login sessions via [SharedPreferences].
///
/// Fields:
/// - [_formKey]: key used to validate and save the current state of the login form
/// - [_usernameController]: controller for the username [TextFormField]
/// - [_passwordController]: controller for the password [TextFormField]
/// - [_isLoading]: whether the authentication process is currently in progress
/// - [_obscurePassword]: whether the password text should be hidden from view
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    // Prevent memory leaks by disposing controllers
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates the form, authenticates the user, and navigates to [HomePage].
  ///
  /// Side effects:
  /// - Sets [_isLoading] during the async operation
  /// - Saves `loggedInUser` key to [SharedPreferences] on success
  /// - Displays an error [SnackBar] if credentials are invalid
  /// - Throws an exception if the network or storage operation fails
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    User? user = await MockDatabase.login(
      _usernameController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedInUser', user.username);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(currentUser: user)),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('Invalid username or password.'),
            ],
          ),
          backgroundColor: Colors.redAccent.shade200,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.grey),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_person_rounded, size: 64, color: Color(0xFF58CC02)),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to Quackle',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Log in to continue your journey.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                  const SizedBox(height: 40),

                  _buildTextField(
                    controller: _usernameController,
                    label: 'Username',
                    icon: Icons.person_outline,
                    validator: (value) => value!.isEmpty ? 'Please enter your username' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscure: _obscurePassword,
                    validator: (value) => value!.isEmpty ? 'Please enter your password' : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF58CC02),
                          ),
                        )
                      : Custom3DButton(
                          text: 'LOG IN',
                          onPressed: _handleLogin,
                          backgroundColor: const Color(0xFF58CC02),
                          shadowColor: const Color(0xFF48A901),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a styled [TextFormField] with a prefix icon and optional suffix widget.
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF58CC02), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
        ),
      ),
    );
  }
}
