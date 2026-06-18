import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/campos/domain/entities/field.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldDetailPage extends StatelessWidget {
  final String fieldId;

  const FieldDetailPage({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final field = MockData.fields.where((f) => f.id == fieldId).firstOrNull;
    final courts = MockData.courts[fieldId] ?? [];

    if (field == null) {
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
              const Text('Campo não encontrado', style: AppTextStyles.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          EmptyState(
            icon: PhosphorIcons.soccerBall(),
            title: 'Campo não encontrado',
            description: 'O campo com ID "$fieldId" não existe ou foi removido.',
            actionLabel: 'Voltar para campos',
            onAction: () => context.go('/dashboard/fields'),
          ),
        ],
      );
    }

    final addressParts = [
      if (field.street != null) field.street!,
      field.city,
      field.state,
    ];
    final fullAddress = addressParts.join(', ');

    final fieldReservations =
        MockData.reservations.where((r) => r.fieldId == field.id).toList();
    final confirmedToday = fieldReservations
        .where(
          (r) =>
              r.date.day == DateTime.now().day &&
              (r.status == ReservationStatus.confirmed ||
                  r.status == ReservationStatus.completed),
        )
        .length;

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
            Expanded(
              child: Text(field.name, style: AppTextStyles.titleLarge),
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
              Text(field.name, style: AppTextStyles.titleLarge),
              const SizedBox(height: AppSpacing.sm),

              if (fullAddress.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.mapPin(),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(fullAddress, style: AppTextStyles.bodySmall),
                  ],
                ),

              if (field.contactPhone != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.phone(),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      _formatPhone(field.contactPhone!),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],

              if (field.contactEmail != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.envelope(),
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      field.contactEmail!,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ],

              if (field.description != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  field.description!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],

              const Divider(height: AppSpacing.xxl),

              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _StatChip(
                    label: '${courts.length} quadra(s)',
                    icon: PhosphorIcons.soccerBall(),
                  ),
                  _StatChip(
                    label: 'Plano ${field.plan.name.toUpperCase()}',
                    icon: PhosphorIcons.crown(),
                  ),
                  _StatChip(
                    label: confirmedToday > 0
                        ? 'Hoje: $confirmedToday reserva(s)'
                        : 'Sem reservas hoje',
                    icon: PhosphorIcons.chartBar(),
                  ),
                  _StatChip(
                    label: field.status.name == 'active' ? 'Ativo' : 'Inativo',
                    icon: PhosphorIcons.checkCircle(),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

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

        if (courts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text('Quadras', style: AppTextStyles.titleSmall),
                ),
                const Divider(height: 1),
                ...courts.map(
                  (court) => ListTile(
                    leading: Icon(
                      PhosphorIcons.soccerBall(),
                      size: 18,
                      color: court.isActive
                          ? AppColors.primary
                          : AppColors.textDisabled,
                    ),
                    title: Text(court.name, style: AppTextStyles.bodyMedium),
                    subtitle: Text(
                      '${court.modality.name.toUpperCase()} · ${court.capacity}v${court.capacity}${court.surface != null ? ' · ${court.surface!.name}' : ''}',
                      style: AppTextStyles.bodySmall,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: court.isActive
                            ? AppColors.primarySurface
                            : AppColors.errorSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        court.isActive ? 'Ativa' : 'Inativa',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: court.isActive
                              ? AppColors.primary
                              : AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
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