import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';

// =============================================================================
// SCRUM-15 — Componentes Base: AppButton, AppInput, AppCard,
//             AppBar customizada e BottomNavigationBar
// =============================================================================

// -----------------------------------------------------------------------------
// AppButton
// Variantes: primary (verde sólido), outline (borda verde), danger (vermelho)
// -----------------------------------------------------------------------------

enum AppButtonVariant { primary, outline, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  });

  /// Botão primário verde (ex: "Entrar", "Criar Partida", "Registrar resultado")
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  }) : variant = AppButtonVariant.primary;

  /// Botão outline verde (ex: "Convidar Jogador", "Entrar" na lista)
  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  }) : variant = AppButtonVariant.outline;

  /// Botão de ação destrutiva (ex: "Cancelar partida", "Sair da conta")
  const AppButton.danger({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  }) : variant = AppButtonVariant.danger;

  Color get _iconColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return AppColors.textOnPrimary;
      case AppButtonVariant.outline:
        return AppColors.primary;
      case AppButtonVariant.danger:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary
                  ? AppColors.textOnPrimary
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconMd, color: _iconColor),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label),
            ],
          );

    switch (variant) {
      case AppButtonVariant.primary:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(onPressed: onPressed, child: child),
        );

      case AppButtonVariant.outline:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: OutlinedButton(onPressed: onPressed, child: child),
        );

      case AppButtonVariant.danger:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape:
                  RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
              textStyle:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
            child: child,
          ),
        );
    }
  }
}

// -----------------------------------------------------------------------------
// AppButtonSmall
// Botão compacto usado em listas (ex: "Desafiar", "Entrar", "Solicitar vaga")
// -----------------------------------------------------------------------------

class AppButtonSmall extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const AppButtonSmall({
    super.key,
    required this.label,
    this.onPressed,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(80, AppSizes.buttonHeightSmall),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          textStyle: AppTextStyles.labelMedium
              .copyWith(color: AppColors.textOnPrimary),
        ),
        child: Text(label),
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(80, AppSizes.buttonHeightSmall),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        textStyle: AppTextStyles.labelMedium,
      ),
      child: Text(label),
    );
  }
}

// -----------------------------------------------------------------------------
// AppInput
// Campo de texto com ícone, label e suporte a senha
// -----------------------------------------------------------------------------

class AppInput extends StatefulWidget {
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLength;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const AppInput({
    super.key,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.isPassword && _obscure,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLength: widget.maxLength,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          readOnly: widget.readOnly,
          onTap: widget.onTap,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: widget.hint,
            counterText: widget.maxLength != null ? null : '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    size: AppSizes.iconMd,
                    color: AppColors.textSecondary,
                  )
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                      size: AppSizes.iconMd,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// AppCard
// Card genérico com sombra sutil e border-radius padrão
// -----------------------------------------------------------------------------

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          boxShadow: AppShadows.card,
          border: border,
        ),
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        child: child,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AppStatCard
// Card de estatística (Jogos / Vitórias / Gols) usado no perfil e time
// -----------------------------------------------------------------------------

class AppStatCard extends StatelessWidget {
  final String value;
  final String label;

  const AppStatCard({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.statNumber),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: AppTextStyles.statLabel),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AppTeamAvatar
// Avatar circular com iniciais do time (ex: FU, UN, DR)
// -----------------------------------------------------------------------------

class AppTeamAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  final double fontSize;

  const AppTeamAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = AppSizes.avatarMd,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.textOnPrimary,
          fontWeight: FontWeight.w700,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AppBadge
// Badge de status: Aberta, Fechada, Pendente, Confirmada, Aguardando
// -----------------------------------------------------------------------------

enum AppBadgeType { open, closed, pending, confirmed, waiting }

class AppBadge extends StatelessWidget {
  final AppBadgeType type;

  const AppBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bgColor;
    late Color textColor;

    switch (type) {
      case AppBadgeType.open:
        label = 'Aberta';
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
        break;
      case AppBadgeType.closed:
        label = 'Fechada';
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
        break;
      case AppBadgeType.pending:
        label = 'Pendente';
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
        break;
      case AppBadgeType.confirmed:
        label = 'Confirmada';
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
        break;
      case AppBadgeType.waiting:
        label = 'Aguardando resultado';
        bgColor = const Color(0xFFEEEEEE);
        textColor = AppColors.pending;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AppFilterChip
// Chip de filtro (ex: "Hoje", "Futebol 7", "Society")
// -----------------------------------------------------------------------------

class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: AppRadius.chipRadius,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// AppGradientAppBar
// AppBar com gradiente verde (tela de login, home, busca)
// -----------------------------------------------------------------------------

class AppGradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? expandedHeight;

  const AppGradientAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.expandedHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: showBackButton
            ? IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(),
                    color: AppColors.textOnPrimary),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
        actions: actions,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.appBarHeight);
}

// -----------------------------------------------------------------------------
// AppWarningBanner
// Banner de aviso amarelo (ex: "Cancelamento tardio registrará penalidade")
// -----------------------------------------------------------------------------

class AppWarningBanner extends StatelessWidget {
  final String message;

  const AppWarningBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.warningIcon.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(PhosphorIcons.warning(),
              color: AppColors.warningIcon, size: AppSizes.iconMd),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodySmall.copyWith(
                  color: const Color(0xFF5D4037),
                )),
          ),
        ],
      ),
    );
  }
}
