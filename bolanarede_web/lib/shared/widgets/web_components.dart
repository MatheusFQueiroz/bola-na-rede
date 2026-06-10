import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';

// =============================================================================
// AppButton
// =============================================================================

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

  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outline({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppSizes.buttonHeight,
  }) : variant = AppButtonVariant.outline;

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
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.buttonRadius,
              ),
              textStyle:
                  AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
            child: child,
          ),
        );
    }
  }
}

// =============================================================================
// AppInput
// =============================================================================

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
                      _obscure
                          ? PhosphorIcons.eye()
                          : PhosphorIcons.eyeSlash(),
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

// =============================================================================
// AppCard
// =============================================================================

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

// =============================================================================
// StatusBadge
// =============================================================================

class StatusBadge extends StatelessWidget {
  final ReservationStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bgColor;
    late Color textColor;

    switch (status) {
      case ReservationStatus.confirmed:
        label = 'Confirmado';
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
      case ReservationStatus.pending:
        label = 'Pendente';
        bgColor = AppColors.pendingSurface.withValues(alpha: 0.3);
        textColor = AppColors.pending;
      case ReservationStatus.cancelled:
        label = 'Cancelado';
        bgColor = AppColors.errorSurface;
        textColor = AppColors.error;
      case ReservationStatus.completed:
        label = 'Concluído';
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
      case ReservationStatus.noShow:
        label = 'No-show';
        bgColor = const Color(0xFFFFF3E0);
        textColor = const Color(0xFFE65100);
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

// =============================================================================
// ChannelBadge
// =============================================================================

class ChannelBadge extends StatelessWidget {
  final ReservationChannel channel;

  const ChannelBadge({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bgColor;
    late Color textColor;

    switch (channel) {
      case ReservationChannel.bolanarededbApp:
        label = 'App';
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
      case ReservationChannel.manual:
        label = 'Manual';
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
      case ReservationChannel.whatsapp:
        label = 'WhatsApp';
        bgColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF25D366);
      case ReservationChannel.phone:
        label = 'Telefone';
        bgColor = const Color(0xFFF3E5F5);
        textColor = const Color(0xFF6A1B9A);
      case ReservationChannel.link:
        label = 'Link';
        bgColor = const Color(0xFFE0F7FA);
        textColor = const Color(0xFF00695C);
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

// =============================================================================
// PaymentBadge
// =============================================================================

class PaymentBadge extends StatelessWidget {
  final PaymentStatus status;

  const PaymentBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    late String label;
    late Color bgColor;
    late Color textColor;

    switch (status) {
      case PaymentStatus.paid:
        label = 'Pago';
        bgColor = AppColors.primarySurface;
        textColor = AppColors.primary;
      case PaymentStatus.unpaid:
        label = 'Não pago';
        bgColor = AppColors.errorSurface;
        textColor = AppColors.error;
      case PaymentStatus.refunded:
        label = 'Estornado';
        bgColor = AppColors.warningSurface;
        textColor = AppColors.warning;
      case PaymentStatus.external:
        label = 'Externo';
        bgColor = AppColors.surfaceVariant;
        textColor = AppColors.textSecondary;
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

// =============================================================================
// EmptyState
// =============================================================================

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(label: actionLabel!, onPressed: onAction),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// LoadingState (Skeleton)
// =============================================================================

class SkeletonLoader extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonLoader({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = AppRadius.xs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
