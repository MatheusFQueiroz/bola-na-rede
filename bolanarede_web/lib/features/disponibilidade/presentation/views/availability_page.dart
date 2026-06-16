import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class AvailabilityPage extends StatelessWidget {
  final String fieldId;

  const AvailabilityPage({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final days = ['SEG 9', 'TER 10', 'QUA 11', 'QUI 12', 'SEX 13', 'SÁB 14', 'DOM 15'];
    final hours = [
      '08:00',
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
      '22:00',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Grade de Disponibilidade',
                style: AppTextStyles.titleLarge,
              ),
            ),
            AppButton.outline(
              label: 'Bloquear horário',
              icon: PhosphorIcons.prohibit(),
              width: 180,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 900,
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.border)),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 80),
                        ...days.map(
                          (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Grid
                  ...hours.map(
                    (hour) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: 2,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.divider),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 80,
                            child: Text(
                              hour,
                              style: AppTextStyles.labelSmall,
                            ),
                          ),
                          ...List.generate(7, (dayIdx) {
                            final isBlocked =
                                hour == '10:00' && dayIdx == 0;
                            final isReserved =
                                hour == '20:00' && dayIdx == 1;
                            return Expanded(
                              child: Container(
                                height: 32,
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: isBlocked
                                      ? AppColors.pendingSurface
                                      : isReserved
                                          ? AppColors.primary
                                          : AppColors.primarySurface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xs),
                                ),
                                alignment: Alignment.center,
                                child: isBlocked
                                    ? Icon(
                                        PhosphorIcons.minus(),
                                        size: 12,
                                        color: AppColors.textOnPrimary,
                                      )
                                    : isReserved
                                        ? Icon(
                                            PhosphorIcons.check(),
                                            size: 12,
                                            color: AppColors.textOnPrimary,
                                          )
                                        : Icon(
                                            PhosphorIcons.check(),
                                            size: 12,
                                            color: AppColors.primary,
                                          ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  // Legenda
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        _LegendItem(
                          color: AppColors.primarySurface,
                          label: 'Disponível',
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _LegendItem(
                          color: AppColors.pendingSurface,
                          label: 'Bloqueado',
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        _LegendItem(
                          color: AppColors.primary,
                          label: 'Reservado',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}
