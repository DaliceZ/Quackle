/*
 * File: theme_data.dart
 * Description: Defines the GameTheme data model and ThemeDatabase, which
 * contains all purchasable visual themes for the Quackle application.
 *
 * Dependencies:
 * - flutter/material.dart
 * - flutter/services.dart
 *
 * Responsibilities:
 * - Models per-theme colors for tiles, UI, and status bar.
 * - Provides ThemeDatabase.themes as the master theme catalog.
 * - Provides ThemeDatabase.getTheme() for safe theme lookup by ID.
 *
 * Author:660510649 Detnarin Karinchai
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/// Represents a single visual theme that can be applied to the entire app.
///
/// Fields:
/// - [id]: unique string identifier used for persistence
/// - [name]: human-readable display name shown in the Store
/// - [price]: cost in coins; `0` means the theme is free
/// - [correct]: tile color for a correctly placed letter (green equivalent)
/// - [present]: tile color for a letter in the word but wrong position (yellow equivalent)
/// - [absent]: tile color for a letter not in the word (grey equivalent)
/// - [backgroundColor]: scaffold/page background color
/// - [textColor]: primary text and icon color for AppBar and headings
/// - [brightness]: used to set the system status-bar icon brightness
class GameTheme {
  final String id;
  final String name;
  final int price;

  final Color correct;
  final Color present;
  final Color absent;

  final Color backgroundColor;
  final Color textColor;
  final Brightness brightness;

  GameTheme({
    required this.id,
    required this.name,
    required this.price,
    required this.correct,
    required this.present,
    required this.absent,
    required this.backgroundColor,
    required this.textColor,
    required this.brightness,
  });
}

/// Static catalog of all [GameTheme] instances available in the application.
///
/// Usage:
/// - Access the full list via [ThemeDatabase.themes]
/// - Retrieve a theme by ID with [ThemeDatabase.getTheme]
class ThemeDatabase {
  /// The collection of available themes, ranging from free to legendary.
  static List<GameTheme> themes = [
    // 1. Free
    GameTheme(
      id: 'classic',
      name: 'Classic Green',
      price: 0,
      correct: const Color(0xFF58CC02),
      present: const Color(0xFFC9B458),
      absent: const Color(0xFF787C7E),
      backgroundColor: Colors.white,
      textColor: Colors.black,
      brightness: Brightness.light,
    ),

    // 2
    GameTheme(
      id: 'pastel',
      name: 'Sweet Pastel',
      price: 50,
      correct: const Color(0xFF88C9A1),
      present: const Color(0xFFFFD166),
      absent: Colors.grey,
      backgroundColor: const Color(0xFFFFFBE6),
      textColor: Colors.brown,
      brightness: Brightness.light,
    ),

    // 3
    GameTheme(
      id: 'neon',
      name: 'Cyber Neon',
      price: 100,
      correct: const Color(0xFF00FF00),
      present: const Color(0xFFFFD166),
      absent: Colors.grey,
      backgroundColor: const Color(0xFF121212),
      textColor: Colors.white,
      brightness: Brightness.dark,
    ),

    // 4
    GameTheme(
      id: 'dark',
      name: 'Dark Mode',
      price: 200,
      correct: const Color(0xFF81C784),
      present: const Color(0xFFFFD166),
      absent: Colors.grey,
      backgroundColor: const Color(0xFF212121),
      textColor: Colors.white70,
      brightness: Brightness.dark,
    ),

    // 5
    GameTheme(
      id: 'midnight',
      name: 'Midnight Purple',
      price: 300,
      correct: const Color(0xFF9D50BB),
      present: const Color(0xFF6E48AA),
      absent: const Color(0xFF2D3436),
      backgroundColor: const Color(0xFF0F0C29),
      textColor: Colors.white,
      brightness: Brightness.dark,
    ),

    // 6
    GameTheme(
      id: 'sunset',
      name: 'Sunset Glow',
      price: 350,
      correct: const Color(0xFFFF6B35),
      present: const Color(0xFFFFB627),
      absent: const Color(0xFF6C757D),
      backgroundColor: const Color(0xFFFFF3E0),
      textColor: const Color(0xFF5D4037),
      brightness: Brightness.light,
    ),

    // 7
    GameTheme(
      id: 'sakura',
      name: 'Sakura Blossom',
      price: 400,
      correct: const Color(0xFFFF7597),
      present: const Color(0xFFFFB7B2),
      absent: const Color(0xFFE0E0E0),
      backgroundColor: const Color(0xFFFFF0F3),
      textColor: const Color(0xFFC9184A),
      brightness: Brightness.light,
    ),

    // 8
    GameTheme(
      id: 'ice',
      name: 'Frozen Ice',
      price: 450,
      correct: const Color(0xFF4CC9F0),
      present: const Color(0xFF90DBF4),
      absent: const Color(0xFFADB5BD),
      backgroundColor: const Color(0xFFEAF8FF),
      textColor: const Color(0xFF023E8A),
      brightness: Brightness.light,
    ),

    // 9
    GameTheme(
      id: 'ocean',
      name: 'Deep Ocean',
      price: 500,
      correct: const Color(0xFF0077B6),
      present: const Color(0xFF90E0EF),
      absent: const Color(0xFFCFD8DC),
      backgroundColor: const Color(0xFFCAF0F8),
      textColor: const Color(0xFF03045E),
      brightness: Brightness.light,
    ),

    // 10
    GameTheme(
      id: 'candy',
      name: 'Candy Pop',
      price: 600,
      correct: const Color(0xFFFF4D6D),
      present: const Color(0xFFFFC300),
      absent: const Color(0xFFD3D3D3),
      backgroundColor: const Color(0xFFFFF0F6),
      textColor: const Color(0xFF9D174D),
      brightness: Brightness.light,
    ),

    // 11
    GameTheme(
      id: 'matrix',
      name: 'Matrix Code',
      price: 700,
      correct: const Color(0xFF00FF41),
      present: const Color(0xFF39FF14),
      absent: const Color(0xFF1B4332),
      backgroundColor: const Color(0xFF000000),
      textColor: const Color(0xFF00FF41),
      brightness: Brightness.dark,
    ),

    // 12
    GameTheme(
      id: 'galaxy',
      name: 'Galaxy Night',
      price: 800,
      correct: const Color(0xFF7B2CBF),
      present: const Color(0xFF9D4EDD),
      absent: const Color(0xFF3C096C),
      backgroundColor: const Color(0xFF10002B),
      textColor: const Color(0xFFE0AAFF),
      brightness: Brightness.dark,
    ),

    // 13
    GameTheme(
      id: 'lava',
      name: 'Volcanic Lava',
      price: 1000,
      correct: const Color(0xFFD00000),
      present: const Color(0xFFFF8C00),
      absent: const Color(0xFF3D3D3D),
      backgroundColor: const Color(0xFF1A1A1A),
      textColor: const Color(0xFFFFE3E3),
      brightness: Brightness.dark,
    ),

    // 14 Legendary
    GameTheme(
      id: 'legendary',
      name: 'Golden Emperor',
      price: 5000,
      correct: const Color(0xFFFFD700),
      present: const Color(0xFFFFC300),
      absent: const Color(0xFF5C5C5C),
      backgroundColor: const Color(0xFF1A1A1A),
      textColor: const Color(0xFFFFD700),
      brightness: Brightness.dark,
    ),
  ];

  /// Returns the [GameTheme] matching the provided [id].
  ///
  /// If the requested theme cannot be found, it returns the first theme in
  /// the [themes] list as a default fallback.
  static GameTheme getTheme(String id) {
    return themes.firstWhere((t) => t.id == id, orElse: () => themes[0]);
  }
}
