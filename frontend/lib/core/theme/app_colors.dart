import 'package:flutter/material.dart';

/// App color palette — single source of truth for all theme colors.
/// Usage: AppColors.primary, AppColors.background, etc.
abstract class AppColors {
  // ── Core Palette ──────────────────────────────────────────────────────────

  /// Pure off-white — used for cards, surfaces, and light backgrounds
  static const Color white = Color(0xFFFEFEFE);

  /// Soft sky-blue — used for primary actions and key UI elements
  static const Color skyBlue = Color(0xFFDBE6EF);

  /// Warm sand — used for accents, highlights, and secondary surfaces
  static const Color sand = Color(0xFFF5EBE2);

  /// Muted steel-blue — used for deep backgrounds and footer areas
  static const Color steelBlue = Color(0xFFC9DAEA);

  // ── Semantic Aliases ──────────────────────────────────────────────────────

  static const Color background   = white;
  static const Color surface      = sand;
  static const Color surfaceAlt   = skyBlue;
  static const Color primary      = steelBlue;
  static const Color primaryLight = skyBlue;

  /// Gradient used on the login/splash screen background
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [skyBlue, white, sand],
    stops: [0.0, 0.5, 1.0],
  );

  /// Gradient used on primary CTA buttons
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [steelBlue, skyBlue],
  );

  // ── Text Colors ───────────────────────────────────────────────────────────

  static const Color textPrimary   = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textHint      = Color(0xFFB0BEC5);

  // ── Utility ───────────────────────────────────────────────────────────────

  static const Color divider      = Color(0xFFE8ECF0);
  static const Color shadow       = Color(0x1A2C3E50);
  static const Color error        = Color(0xFFE57373);
  static const Color success      = Color(0xFF81C784);
  static const Color inputBorder  = steelBlue;
  static const Color inputFill    = white;

  // ── Order Status Colors ─────────────────────────────────────────────────────

  static const Color statusPending    = Color(0xFFFFA500);
  static const Color statusProcessing = Color(0xFF2196F3);
  static const Color statusShipped    = Color(0xFF9C27B0);
  static const Color statusDelivered  = Color(0xFF4CAF50);
  static const Color statusCancelled  = Color(0xFFF44336);

  // ── Payment Status Colors ──────────────────────────────────────────────────

  static const Color paymentPaid    = Color(0xFF4CAF50);
  static const Color paymentPending = Color(0xFFFFA500);
  static const Color paymentFailed  = Color(0xFFF44336);

  // ── Stripe Color ───────────────────────────────────────────────────────────

  static const Color stripe = Color(0xFF635BFF);
}