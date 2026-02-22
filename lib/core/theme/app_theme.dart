/// I-Fridge — Design System & Theme
/// ==================================
/// Premium dark theme with glassmorphic accents and freshness-aware colors.

import 'package:flutter/material.dart';

class IFridgeTheme {
  // --- Core Palette ---
  static const Color primary = Color(0xFF00E676);       // Vibrant green — freshness
  static const Color primaryDark = Color(0xFF00C853);
  static const Color secondary = Color(0xFF00BCD4);     // Teal — coolness
  static const Color accent = Color(0xFFFF6D00);         // Orange — urgency
  static const Color error = Color(0xFFFF1744);           // Red — expired/critical
  
  // --- Background ---
  static const Color bgDark = Color(0xFF0D1117);
  static const Color bgCard = Color(0xFF161B22);
  static const Color bgElevated = Color(0xFF21262D);
  static const Color bgGlass = Color(0x1AFFFFFF);        // 10% white for glass
  
  // --- Text ---
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
  
  // --- Freshness States ---
  static const Color freshGreen = Color(0xFF2EA043);
  static const Color agingAmber = Color(0xFFF0883E);
  static const Color urgentOrange = Color(0xFFDB6D28);
  static const Color criticalRed = Color(0xFFDA3633);
  static const Color expiredGrey = Color(0xFF484F58);

  // --- Tier Badge Colors ---
  static const Color tier1 = Color(0xFF2EA043);          // Full match comfort
  static const Color tier2 = Color(0xFF1F6FEB);          // Full match discovery
  static const Color tier3 = Color(0xFFF0883E);          // Minor shop comfort
  static const Color tier4 = Color(0xFFBC8CFF);          // Minor shop discovery
  static const Color tier5 = Color(0xFF8B949E);          // Global search

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      fontFamily: 'Inter',
      
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        error: error,
        surface: bgCard,
        onPrimary: bgDark,
        onSecondary: textPrimary,
        onSurface: textPrimary,
        onError: textPrimary,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: bgDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bgCard,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      cardTheme: CardThemeData(
        color: bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bgDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: bgElevated,
        labelStyle: const TextStyle(color: textPrimary, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),

      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.06),
        thickness: 1,
      ),
    );
  }
}

/// Convenience alias used by feature screens.
/// Maps semantic names to [IFridgeTheme] constants.
class AppTheme {
  static const Color background = IFridgeTheme.bgDark;
  static const Color surface = IFridgeTheme.bgCard;
  static const Color accent = IFridgeTheme.primary;
  static const Color freshGreen = IFridgeTheme.freshGreen;

  // Tier badge colors
  static const Color tierGold = Color(0xFFFFD700);
  static const Color tierSilver = Color(0xFFC0C0C0);
  static const Color tierBronze = Color(0xFFCD7F32);
}

