/*
 * File: victory_effect.dart
 * Description: Full-screen confetti particle animation displayed on top of
 * other widgets when the player wins a round.
 *
 * Lifecycle:
 * - Created inside the end-game dialog Stack in WordleScreen and FlashcardPage.
 * - Plays once (2.5 seconds) then particles fade out; disposed with the dialog.
 *
 * Responsibilities:
 * - Generates and manages the lifecycle of confetti particle objects.
 * - Orchestrates the animation progress and frame updates.
 * - Renders particles to a [Canvas] with simulated physics and fading.
 *
 * Author: 660510649 Detnarin Karinchai
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'dart:math';

/// Plays a one-shot confetti burst animation overlaying the current screen.
///
/// Wraps itself in [IgnorePointer] so the user can interact with widgets
/// behind the effect while it plays. Spawns 120 [_Particle] instances that
/// fly outward from the centre and fall under simulated gravity, fading out
/// over 2.5 seconds.
class VictoryEffect extends StatefulWidget {
  const VictoryEffect({super.key});

  @override
  State<VictoryEffect> createState() => _VictoryEffectState();
}

/// The logic and particle management state for [VictoryEffect].
///
/// Spawns 120 [_Particle] instances and manages a 2.5-second
/// [AnimationController] to drive the movement and fade effects.
class _VictoryEffectState extends State<VictoryEffect> with SingleTickerProviderStateMixin {
  /// The controller managing the 2.5-second animation lifecycle.
  late AnimationController _controller;

  /// The list of active particles used for rendering.
  final List<_Particle> _particles = [];

  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    for (int i = 0; i < 120; i++) {
      _particles.add(_Particle(
        color: _getRandomColor(),
        x: 0.5,
        y: 0.3,
        angle: _random.nextDouble() * 2 * pi,
        speed: _random.nextDouble() * 20 + 5,
        size: _random.nextDouble() * 8 + 4,
        rotation: _random.nextDouble() * 2 * pi,
      ));
    }

    _controller.addListener(() => setState(() {}));
    _controller.forward();
  }

  /// Returns a random confetti color from a preset palette.
  Color _getRandomColor() {
    List<Color> colors = [
      Colors.green, Colors.blue, Colors.pinkAccent,
      Colors.orange, Colors.purpleAccent, Colors.yellow, Colors.cyan
    ];
    return colors[_random.nextInt(colors.length)];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_particles, _controller.value),
        child: Container(),
      ),
    );
  }
}

/// Internal data model for a single confetti particle.
class _Particle {
  Color color;
  double x, y, angle, speed, size, rotation;

  _Particle({
    required this.color, required this.x, required this.y,
    required this.angle, required this.speed, required this.size, required this.rotation,
  });
}

/// [CustomPainter] that draws all [_Particle] instances for a given animation [progress].
///
/// Each particle moves along its [_Particle.angle] direction, accelerates
/// downward via simulated gravity, rotates, and fades out as [progress]
/// approaches `1.0`.
class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var p in particles) {
      double distance = p.speed * progress * 30;
      double gravity = progress * progress * 500;

      double px = (size.width * p.x) + (cos(p.angle) * distance);
      double py = (size.height * p.y) + (sin(p.angle) * distance) + gravity;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(p.rotation + (progress * 15));

      paint.color = p.color.withOpacity(1.0 - progress);

      if (p.size % 2 > 1) {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size), paint);
      } else {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
