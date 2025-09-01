import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum BoardType { square, aaduPuli }
enum Difficulty { easy, medium, hard }

class AppColors {
  static const Color deepSpace = Color(0xFF1A1D24);
  static const Color cosmicBlue = Color(0xFF2A2F3D);
  static const Color stellarGold = Color(0xFFFFD700);
  static const Color nebulaTeal = Color(0xFF4ECDC4);
  static const Color darkMatter = Color(0xFF121212);
  static const Color starDust = Color(0xFFBDBDBD);
}

class AppGradients {
  static const LinearGradient space = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepSpace, AppColors.cosmicBlue],
  );

  static const LinearGradient jungle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
    stops: [0.0, 0.5, 1.0],
  );
}

class AppTextStyles {
  static TextStyle title(BuildContext context) => GoogleFonts.orbitron(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.stellarGold,
      );

  static TextStyle subtitle(BuildContext context) => GoogleFonts.rajdhani(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle body(BuildContext context) => GoogleFonts.robotoCondensed(
        fontSize: 14,
        color: AppColors.starDust,
      );

  static TextStyle badge(BuildContext context) => GoogleFonts.robotoMono(
        fontSize: 12,
        color: Colors.white,
        letterSpacing: 1.1,
      );
}

class AppDecorations {
  static BoxDecoration panel = BoxDecoration(
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C313E), Color(0xFF1E222C)],
    ),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.35),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
    border: Border.all(color: Colors.white12),
  );

  static BoxDecoration board = BoxDecoration(
    color: const Color(0xFF2A2F3D),
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.4),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ],
    border: Border.all(color: Colors.white24, width: 1),
  );
}

