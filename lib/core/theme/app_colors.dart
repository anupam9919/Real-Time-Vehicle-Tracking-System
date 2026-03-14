import 'package:flutter/material.dart';

/// Centralized color palette for the app.
///
/// Extracts the repeated color values used across all screens
/// (sign_in, home_screen, track, driver_home, bus_stop, admin, etc.).
class AppColors {
  AppColors._();

  // ── Background ──
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1E1E2C);

  // ── Brand Colors ──
  static const Color primary = Color(0xFF6C63FF);    // Purple accent
  static const Color accent = Color(0xFF00C9FF);     // Cyan accent

  // ── Semantic Colors ──
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB74D);

  // ── Live Status ──
  static const Color liveGreen = Colors.greenAccent;

  // ── Glass Effect ──
  static Color glassBackground = Colors.white.withValues(alpha: 0.05);
  static Color glassBorder = Colors.white.withValues(alpha: 0.1);
  static Color glassHighlight = Colors.white.withValues(alpha: 0.15);

  // ── Text ──
  static const Color textPrimary = Colors.white;
  static Color textSecondary = Colors.white.withValues(alpha: 0.7);
  static Color textTertiary = Colors.white.withValues(alpha: 0.54);
  static Color textSubtle = Colors.white.withValues(alpha: 0.38);

  // ── Gradients ──
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6C63FF), Color(0xFF00C9FF)],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F0F1A), Color(0xFF1A1A2E)],
  );
}
