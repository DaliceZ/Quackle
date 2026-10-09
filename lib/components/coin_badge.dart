/*
 * File: coin_badge.dart
 * Description: Reusable widget that displays the player's coin balance with
 * a pop/bounce animation whenever the value changes.
 *
 * Lifecycle:
 * - Created inside the AppBar of HomePage.
 * - Disposed when HomePage is removed from the widget tree.
 *
 *  Responsibilities:
 * - Provides a visual representation of the player's current currency.
 * - Animates numerical transitions using an interpolation (rolling) effect.
 * - Triggers a "pop" scale animation to provide feedback on coin updates.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';

/// Displays [coins] inside a gold gradient pill that pops when the value changes.
///
/// Uses a [TweenSequence] scale animation on coin updates and a
/// [TweenAnimationBuilder] to smoothly roll the number display from the
/// previous value to the new one over 1.2 seconds.
class AnimatedCoinBadge extends StatefulWidget {
  /// The current number of coins to be displayed.
  final int coins;
  const AnimatedCoinBadge({super.key, required this.coins});

  @override
  State<AnimatedCoinBadge> createState() => _AnimatedCoinBadgeState();
}

/// The logic and animation state for [AnimatedCoinBadge].
///
/// Manages the [AnimationController] for the scale effect and tracks
/// the previous coin count to perform numerical interpolation.
class _AnimatedCoinBadgeState extends State<AnimatedCoinBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _oldCoins = 0;

  @override
  void initState() {
    super.initState();
    _oldCoins = widget.coins;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.4).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 60,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(AnimatedCoinBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coins != oldWidget.coins) {
      _oldCoins = oldWidget.coins;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("💰", style: TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutExpo,
              tween: Tween<double>(begin: _oldCoins.toDouble(), end: widget.coins.toDouble()),
              builder: (context, value, child) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
