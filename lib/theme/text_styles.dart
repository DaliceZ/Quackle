/*
 * File: text_styles.dart
 * Description: Provides centralised text style helpers for the Quackle app,
 * including smart bilingual style selection between Thai and English fonts.
 *
 * Dependencies:
 * - google_fonts (Kanit for Thai text)
 *
 * Responsibilities:
 * - Detects the presence of Thai characters in a given string.
 * - Dynamically switches between Google Fonts (Kanit) and system fonts.
 * - Normalizes font weights and spacing for mixed-language UI components.
 *
 * Author: 660510669 Phutawan Fongchan
 * Course: 204311-Mobile Application Development Framework
 */

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Collection of reusable [TextStyle] factory methods for the application.
class AppTextStyles {
  /// Returns a [TextStyle] appropriate for [text], automatically switching
  /// between Kanit (Thai) and the default DINNextRounded font (English).
  ///
  /// Thai text is detected via the Unicode range `\u0E00–\u0E7F`. When Thai
  /// characters are present, [GoogleFonts.kanit] is used with a slightly
  /// lighter weight for better readability. Otherwise a standard [TextStyle]
  /// is returned with all provided parameters applied.
  ///
  /// Parameters:
  /// - [text]: the string that will be rendered, used to detect language
  /// - [fontSize]: optional font size override
  /// - [fontWeight]: optional weight override (Thai defaults to [FontWeight.w500])
  /// - [color]: optional foreground color
  /// - [letterSpacing]: applied only for non-Thai text
  static TextStyle smartStyle(String text, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
  }) {
    bool hasThai = RegExp(r'[\u0E00-\u0E7F]').hasMatch(text);

    if (hasThai) {
      return GoogleFonts.kanit(
        fontSize: fontSize,
        fontWeight: fontWeight ?? FontWeight.w500,
        color: color,
      );
    } else {
      return TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        letterSpacing: letterSpacing,
      );
    }
  }
}
