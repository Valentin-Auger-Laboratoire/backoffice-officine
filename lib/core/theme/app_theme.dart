import 'package:flutter/material.dart';

/// Palette inspirée de l'identité officinale : vert pharmacie + accents
/// d'alerte rouge/orange pour les statuts de stock, sur fond neutre clair
/// adapté à un usage prolongé en back-office (lisibilité, faible fatigue
/// visuelle).
class AppColors {
  static const Color primaire = Color(0xFF0E7C61);       // vert pharmacie
  static const Color primaireFonce = Color(0xFF075A46);
  static const Color fond = Color(0xFFF4F7F6);
  static const Color carte = Color(0xFFFFFFFF);
  static const Color texte = Color(0xFF1C2826);
  static const Color texteSecondaire = Color(0xFF5C6D69);

  static const Color alerteRouge = Color(0xFFD64545);
  static const Color alerteOrange = Color(0xFFE0972C);
  static const Color alerteVert = Color(0xFF2F9E5B);
  static const Color bordure = Color(0xFFE1E8E6);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.fond,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaire,
        primary: AppColors.primaire,
        surface: AppColors.carte,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.carte,
        foregroundColor: AppColors.texte,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.texte,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.carte,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.bordure),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaire,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: AppColors.texte, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(color: AppColors.texte, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: AppColors.texteSecondaire),
      ),
    );
  }
}
