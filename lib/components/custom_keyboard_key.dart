/*
 * File: custom_keyboard_key.dart
 * Description: Reusable 3D keyboard key widget used in the Wordle game screen.
 * Plays a tap sound, triggers haptic feedback, and animates a press-down effect.
 *
 * Dependencies:
 * - audioplayers (local AudioPlayer per key instance)
 * - flutter/services (HapticFeedback)
 *
 * Lifecycle:
 * - Created inside _buildKeyboard() in WordleScreen.
 * - Disposed when WordleScreen is removed from the widget tree.
 *
 * Responsibilities:
 * - Handles low-latency audio feedback (click sounds) for keyboard interaction.
 * - Triggers physical haptic feedback to simulate a tactile typing experience.
 * - Adapts visual state (color/labels) based on game-logic letter status.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

/// A single key in the on-screen Wordle keyboard with a 3D press animation.
///
/// Fields:
/// - [char]: the letter, "ENTER", or "DEL" label displayed on the key
/// - [keyColor]: background color reflecting the letter's [LetterStatus]
/// - [textColor]: foreground color for the key label
/// - [flex]: flex factor used inside the parent [Row]
/// - [onTap]: callback invoked when the key is released
class Custom3DKey extends StatefulWidget {
  final String char;
  final Color keyColor;
  final Color textColor;
  final int flex;
  final VoidCallback onTap;

  const Custom3DKey({
    super.key,
    required this.char,
    required this.keyColor,
    required this.textColor,
    required this.flex,
    required this.onTap,
  });

  @override
  State<Custom3DKey> createState() => _Custom3DKeyState();
}

/// The logic and feedback state for [Custom3DKey].
///
/// Manages the [AudioPlayer] for sound effects and handles
/// gesture callbacks to drive haptics and animation.
class _Custom3DKeyState extends State<Custom3DKey> {
  /// Whether the key is currently being pressed down.
  bool _isPressed = false;
  /// The player used for low-latency tap sound effects.
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  /// Animates the key into its pressed state and provides feedback.
  /// Side effects:
  /// - Plays a keyboard tap sound effect.
  /// - Triggers a light haptic impact on the device.
  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    HapticFeedback.lightImpact();
    _audioPlayer.play(AssetSource('keyboard_sound.ogg'), volume: 1);
  }

  /// Releases the pressed state and invokes [onTap].
  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    widget.onTap();
  }

  /// Cancels the press animation without firing [onTap] callback.
  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: widget.flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            height: 45.0,
            margin: EdgeInsets.only(
              top: _isPressed ? 4.0 : 0.0,
              bottom: _isPressed ? 0.0 : 4.0,
            ),
            decoration: BoxDecoration(
              color: widget.keyColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _isPressed
                  ? []
                  : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.20),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: widget.char == "DEL"
                ? Icon(Icons.backspace_outlined, size: 22, color: widget.textColor)
                : Text(
              widget.char,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.char == "ENTER" ? 12 : 16,
                color: widget.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
