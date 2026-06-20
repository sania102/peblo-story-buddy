import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralised brand tokens so colours/sizing aren't scattered through widgets.
///
/// These are Peblo's actual brand values, taken directly from the wireframe's
/// "Style Guidance" panel (not guessed):
///   Primary purple : #6F2BC2
///   Deep purple     : #36165E
///   Typography      : Poppins
///   Tone            : Joyful, warm, curious. Aged 6-10.
/// A light lavender background and soft cream card surface were added on top
/// of those two anchor colours to keep contrast comfortable for a 6-10 year
/// old reader without introducing any colour the wireframe didn't license.
class AppColors {
  static const Color background = Color(0xFFF3EEFB); // soft lavender wash
  static const Color primary = Color(0xFF6F2BC2); // Peblo brand purple
  static const Color primaryDark = Color(0xFF36165E); // Peblo deep purple
  static const Color accent = Color(0xFFFF8A3D); // warm orange accent (CTA highlights)
  static const Color success = Color(0xFF3DBE6C); // grass green
  static const Color error = Color(0xFFE85D5D); // soft red, not alarming
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF36165E); // reuse deep purple for headings/body
  static const Color textMuted = Color(0xFF9D8AC2);

  static const List<Color> confettiPalette = [
    primary,
    primaryDark,
    accent,
    success,
    Color(0xFFFFC94D),
  ];
}

class AppTextStyles {
  static TextStyle storyText = GoogleFonts.poppins(
    fontSize: 19,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
  );

  static TextStyle heading = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: AppColors.textDark,
  );

  static TextStyle button = GoogleFonts.poppins(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static TextStyle appBarTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
  );
}
