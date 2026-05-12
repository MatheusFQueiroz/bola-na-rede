import 'package:flutter/material.dart';

// =============================================================================
// SCRUM-16 — Tokens de Design: BolaNaRede
// Importados do Figma via análise do Design System
// =============================================================================

/// Paleta de cores do BolaNaRede
abstract class AppColors {
  // --- Cores Primárias (Verde) ---
  static const Color primary        = Color(0xFF2E7D32); // Verde escuro – AppBar, botão primário
  static const Color primaryMedium  = Color(0xFF388E3C); // Verde médio – gradiente
  static const Color primaryLight   = Color(0xFF43A047); // Verde claro – hover, destaques
  static const Color primarySurface = Color(0xFFE8F5E9); // Verde superfície – chip selecionado
  static const Color primaryBorder  = Color(0xFFA5D6A7); // Verde borda – outline do chip

  // --- Cores de Texto ---
  static const Color textPrimary   = Color(0xFF1B1B1B); // Texto principal
  static const Color textSecondary = Color(0xFF757575); // Texto secundário / placeholder
  static const Color textDisabled  = Color(0xFFBDBDBD); // Texto desabilitado
  static const Color textOnPrimary = Color(0xFFFFFFFF); // Texto sobre fundo verde

  // --- Background ---
  static const Color background    = Color(0xFFF5F5F5); // Fundo geral
  static const Color surface       = Color(0xFFFFFFFF); // Cards e modais
  static const Color surfaceVariant = Color(0xFFF8F8F8);

  // --- Semânticas ---
  static const Color success        = Color(0xFF4CAF50); // Confirmado / Aberta
  static const Color warning        = Color(0xFFFFF8E1); // Fundo de alerta
  static const Color warningIcon    = Color(0xFFF9A825); // Ícone de alerta
  static const Color error          = Color(0xFFD32F2F); // Cancelar / erro
  static const Color errorSurface   = Color(0xFFFFEBEE);
  static const Color pending        = Color(0xFF616161); // Badge "Pendente"
  static const Color pendingSurface = Color(0xFF9E9E9E);

  // --- Borda / Divisor ---
  static const Color border  = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // --- Avatares de times ---
  static const Color avatarGreen  = Color(0xFF43A047);
  static const Color avatarBlue   = Color(0xFF1565C0);
  static const Color avatarRed    = Color(0xFFC62828);
  static const Color avatarOrange = Color(0xFFE65100);
  static const Color avatarPurple = Color(0xFF6A1B9A);
  static const Color avatarTeal   = Color(0xFF00695C);
}

/// Gradientes
abstract class AppGradients {
  static const LinearGradient primaryVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
  );

  static const LinearGradient primaryHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
  );
}

/// Tipografia
abstract class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary, letterSpacing: -0.5,
  );
  static const TextStyle titleLarge = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle labelLarge = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary, letterSpacing: 0.2,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle statNumber = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );
  static const TextStyle statLabel = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static const TextStyle link = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.primary,
  );
  static const TextStyle errorText = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.error,
  );
}

/// Espaçamentos
abstract class AppSpacing {
  static const double xs    = 4.0;
  static const double sm    = 8.0;
  static const double md    = 12.0;
  static const double lg    = 16.0;
  static const double xl    = 20.0;
  static const double xxl   = 24.0;
  static const double xxxl  = 32.0;
  static const double screenPadding = 16.0;
  static const double cardPadding   = 16.0;
}

/// Border radius
abstract class AppRadius {
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 24.0;
  static const double full = 100.0;

  static BorderRadius get cardRadius   => BorderRadius.circular(md);
  static BorderRadius get buttonRadius => BorderRadius.circular(full);
  static BorderRadius get inputRadius  => BorderRadius.circular(sm);
  static BorderRadius get chipRadius   => BorderRadius.circular(full);
}

/// Sombras
abstract class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 8, offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get modal => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16, offset: const Offset(0, -4),
    ),
  ];
}

/// Tamanhos de componentes
abstract class AppSizes {
  static const double buttonHeight      = 52.0;
  static const double buttonHeightSmall = 40.0;
  static const double inputHeight       = 52.0;
  static const double avatarLg          = 56.0;
  static const double avatarMd          = 40.0;
  static const double avatarSm          = 32.0;
  static const double appBarHeight      = 56.0;
  static const double bottomNavHeight   = 64.0;
  static const double bottomNavIconSize = 24.0;
  static const double iconMd            = 20.0;
  static const double iconLg            = 24.0;
}
