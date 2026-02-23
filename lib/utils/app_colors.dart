import 'package:flutter/material.dart';

class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF00C851);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF00A040);
  static const Color secondary = Color(0xFFFF8C00);
  static const Color secondaryLight = Color(0xFFFFB347);
  static const Color secondaryDark = Color(0xFFE67E00);
  
  // Couleurs de fond
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9E9E9E);
  
  // Couleurs d'état
  static const Color success = Color(0xFF28A745);
  static const Color successLight = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFD54F);
  static const Color error = Color(0xFFDC3545);
  static const Color errorLight = Color(0xFFFF5722);
  static const Color info = Color(0xFF17A2B8);
  static const Color infoLight = Color(0xFF2196F3);
  
  // Couleurs spécifiques
  static const Color shadowColor = Color(0x1A000000);
  static const Color dividerColor = Color(0xFFE9ECEF);
  static const Color borderColor = Color(0xFFDEE2E6);
  static const Color overlayColor = Color(0x80000000);
  
  // Couleurs pour les prix
  static const Color priceColor = Color(0xFF00C851);
  static const Color discountColor = Color(0xFFFF4444);
  
  // Couleurs pour les badges et statuts
  static const Color badgeNew = Color(0xFFFF6B6B);
  static const Color badgeHot = Color(0xFFFF8C00);
  static const Color badgePopular = Color(0xFF4ECDC4);
  static const Color badgeVegetarian = Color(0xFF95E1D3);

  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondary],
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB347), Color(0xFFFF8C00)],
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4CAF50), Color(0xFF00C851)],
  );
  
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );
  
  // Couleurs avec opacité
  static Color get primaryWithOpacity10 => primary.withOpacity(0.1);
  static Color get primaryWithOpacity20 => primary.withOpacity(0.2);
  static Color get secondaryWithOpacity10 => secondary.withOpacity(0.1);
  static Color get secondaryWithOpacity20 => secondary.withOpacity(0.2);
  static Color get shadowWithOpacity => const Color(0x0F000000);
  
  // Couleurs pour les thèmes sombres (pour usage futur)
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF2D2D2D);
  static const Color darkTextPrimary = Color(0xFFFFFFFF);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
}

