import 'package:flutter/material.dart';

abstract final class AppColors {
  static const light = AppColorScheme(
    primary: Color(0xFF2E7D32),
    primaryMedium: Color(0xFF388E3C),
    primaryLight: Color(0xFF43A047),
    primarySurface: Color(0xFFE8F5E9),
    primaryBorder: Color(0xFFA5D6A7),
    onPrimary: Color(0xFFFFFFFF),
    background: Color(0xFFF5F5F5),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF8F8F8),
    textPrimary: Color(0xFF1B1B1B),
    textSecondary: Color(0xFF757575),
    textDisabled: Color(0xFFBDBDBD),
    border: Color(0xFFE0E0E0),
    divider: Color(0xFFEEEEEE),
    success: Color(0xFF4CAF50),
    warning: Color(0xFFF9A825),
    warningSurface: Color(0xFFFFF8E1),
    error: Color(0xFFD32F2F),
    errorSurface: Color(0xFFFFEBEE),
    pending: Color(0xFF616161),
    pendingSurface: Color(0xFF9E9E9E),
  );

  static const dark = AppColorScheme(
    primary: Color(0xFF66BB6A),
    primaryMedium: Color(0xFF4CAF50),
    primaryLight: Color(0xFF81C784),
    primarySurface: Color(0xFF123D18),
    primaryBorder: Color(0xFF2E7D32),
    onPrimary: Color(0xFF061307),
    background: Color(0xFF101411),
    surface: Color(0xFF171C18),
    surfaceVariant: Color(0xFF1F2520),
    textPrimary: Color(0xFFE8EDE9),
    textSecondary: Color(0xFFA8B0AA),
    textDisabled: Color(0xFF6F7771),
    border: Color(0xFF343B35),
    divider: Color(0xFF2A302B),
    success: Color(0xFF81C784),
    warning: Color(0xFFFFD54F),
    warningSurface: Color(0xFF3A2F08),
    error: Color(0xFFEF9A9A),
    errorSurface: Color(0xFF3F1414),
    pending: Color(0xFFB0B8B1),
    pendingSurface: Color(0xFF3A413B),
  );
}

class AppColorScheme {
  const AppColorScheme({
    required this.primary,
    required this.primaryMedium,
    required this.primaryLight,
    required this.primarySurface,
    required this.primaryBorder,
    required this.onPrimary,
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.border,
    required this.divider,
    required this.success,
    required this.warning,
    required this.warningSurface,
    required this.error,
    required this.errorSurface,
    required this.pending,
    required this.pendingSurface,
  });

  final Color primary;
  final Color primaryMedium;
  final Color primaryLight;
  final Color primarySurface;
  final Color primaryBorder;
  final Color onPrimary;

  final Color background;
  final Color surface;
  final Color surfaceVariant;

  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;

  final Color border;
  final Color divider;

  final Color success;
  final Color warning;
  final Color warningSurface;
  final Color error;
  final Color errorSurface;
  final Color pending;
  final Color pendingSurface;
}
