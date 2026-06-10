import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldDetailPage extends StatelessWidget {
  final String fieldId;

  const FieldDetailPage({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.arrowLeft()),
              onPressed: () => context.go('/dashboard/fields'),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('Detalhe do Campo', style: AppTextStyles.titleLarge),
            ),
            AppButton.outline(
              label: 'Editar',
              icon: PhosphorIcons.pencilSimple(),
              width: 120,
              onPressed: () =>
                  context.go('/dashboard/fields/$fieldId/edit'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Arena Society Xaxim', style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.mapPin(),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text(
                    'Rua das Araucárias, 450 — Xaxim, Curitiba, PR',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    PhosphorIcons.phone(),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  const Text('(41) 99999-1234', style: AppTextStyles.bodySmall),
                ],
              ),
              const Divider(height: AppSpacing.xxl),
              Row(
                children: [
                  _StatChip(label: '2 quadras', icon: PhosphorIcons.soccerBall()),
                  const SizedBox(width: AppSpacing.sm),
                  _StatChip(
                    label: 'Plano PRO',
                    icon: PhosphorIcons.crown(),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatChip(
                    label: 'Hoje: 67% ocupado',
                    icon: PhosphorIcons.chartBar(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Ações rápidas
        Row(
          children: [
            _ActionCard(
              icon: PhosphorIcons.soccerBall(),
              label: 'Gerenciar Quadras',
              onTap: () =>
                  context.go('/dashboard/fields/$fieldId/courts'),
            ),
            const SizedBox(width: AppSpacing.lg),
            _ActionCard(
              icon: PhosphorIcons.currencyCircleDollar(),
              label: 'Regras de Preço',
              onTap: () =>
                  context.go('/dashboard/fields/$fieldId/pricing'),
            ),
            const SizedBox(width: AppSpacing.lg),
            _ActionCard(
              icon: PhosphorIcons.calendarBlank(),
              label: 'Disponibilidade',
              onTap: () =>
                  context.go('/dashboard/fields/$fieldId/availability'),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}
