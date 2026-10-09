/*
 * File: custom_3d_buttton.dart
 * Description: Reusable 3D-style press-down button widget used throughout
 * the Quackle application for primary actions and quiz answer options.
 *
 *
 * Lifecycle:
 * - Created wherever a primary CTA or quiz option button is needed.
 * - Disposed when the parent widget is removed from the tree.
 *
 * Responsibilities:
 * - Renders a consistent 3D visual style with depth and shadow layers.
 * - Orchestrates the "press-down" animation state during user interaction.
 * - Provides semantic feedback colors for quiz success and failure states.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';

/// Possible visual states for [Custom3DButton].
///
/// - [normal]: default appearance using [Custom3DButton.backgroundColor]
/// - [correct]: green highlight used when a quiz answer is correct
/// - [incorrect]: red highlight used when a quiz answer is wrong
enum ButtonState { normal, correct, incorrect }

/// A pressable button with a 3D shadow effect that shifts on tap.
///
/// Fields:
/// - [text]: label displayed in the button centre
/// - [onPressed]: callback invoked after the press-down animation completes
/// - [backgroundColor]: surface color used in [ButtonState.normal]
/// - [shadowColor]: color of the bottom shadow layer
/// - [height] / [width]: explicit dimensions; width defaults to `double.infinity`
/// - [state]: controls the color override for correct/incorrect feedback
/// - [textColor]: overrides the default white label color
/// - [style]: base [TextStyle] merged with size and weight defaults
class Custom3DButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color shadowColor;
  final double height;
  final double width;
  final ButtonState state;
  final Color? textColor;
  final TextStyle? style;

  const Custom3DButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.backgroundColor,
    required this.shadowColor,
    this.height = 55.0,
    this.width = double.infinity,
    this.state = ButtonState.normal,
    this.textColor,
    this.style,
  });

  @override
  State<Custom3DButton> createState() => _Custom3DButtonState();
}

/// The logic and interaction state for [Custom3DButton].
///
/// Resolves dynamic colors based on [ButtonState] and manages
/// the [_isPressed] state to drive the 3D shift animation.
class _Custom3DButtonState extends State<Custom3DButton> {
  bool _isPressed = false;

  /// The surface color resolved based on the current [ButtonState].
  Color get _resolvedBgColor {
    switch (widget.state) {
      case ButtonState.correct:   return Colors.green.shade500;
      case ButtonState.incorrect: return Colors.red.shade500;
      case ButtonState.normal:    return widget.backgroundColor;
    }
  }

  /// The shadow color resolved based on the current [ButtonState].
  Color get _resolvedShadowColor {
    switch (widget.state) {
      case ButtonState.correct:   return Colors.green.shade800;
      case ButtonState.incorrect: return Colors.red.shade800;
      case ButtonState.normal:    return widget.shadowColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) async {
        setState(() => _isPressed = false);
        await Future.delayed(const Duration(milliseconds: 100));
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: SizedBox(
        height: widget.height,
        width: widget.width,
        child: Stack(
          children: [
            Positioned(
              top: 5, bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: _resolvedShadowColor,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              top: _isPressed ? 5.0 : 0.0,
              bottom: _isPressed ? 0.0 : 5.0,
              left: 0, right: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: _resolvedBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: (widget.style ?? const TextStyle()).copyWith(
                      color: widget.textColor ?? Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
