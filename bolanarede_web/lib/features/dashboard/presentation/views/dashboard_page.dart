import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/reservas/domain/entities/reservation.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final todayReservations =
        MockData.reservations.where((r) => r.date.day == 9).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bom dia, João! 👋', style: AppTextStyles.titleLarge),
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    'Aqui está o resumo de hoje',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),
            AppButton.primary(
              label: '+ Nova Reserva',
              icon: PhosphorIcons.plus(),
              width: 180,
              onPressed: () => context.go(AppRoutes.reservationNew),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Métricas
        Row(
          children: [
            _MetricCard(
              icon: PhosphorIcons.calendarBlank(),
              label: 'Reservas hoje',
              value: '${todayReservations.length}',
              change: '+3 vs ontem',
              isPositive: true,
            ),
            const SizedBox(width: AppSpacing.lg),
            _MetricCard(
              icon: PhosphorIcons.currencyCircleDollar(),
              label: 'Receita hoje',
              value: 'R\$ 1.240',
              change: '+R\$ 200 vs ont.',
              isPositive: true,
            ),
            const SizedBox(width: AppSpacing.lg),
            _MetricCard(
              icon: PhosphorIcons.chartBar(),
              label: 'Ocupação',
              value: '78%',
              change: '-5% vs sem.',
              isPositive: false,
            ),
            const SizedBox(width: AppSpacing.lg),
            _MetricCard(
              icon: PhosphorIcons.usersThree(),
              label: 'Clientes',
              value: '847',
              change: '+12 este mês',
              isPositive: true,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Próximas reservas
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Próximas Reservas — Hoje, 09/06/2026',
                    style: AppTextStyles.titleSmall,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.reservations),
                    child: const Text('Ver todas'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              _buildReservationTable(todayReservations),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Atenção: slots liberados
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.warningSurface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: AppColors.warning.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            children: [
              Icon(
                PhosphorIcons.warning(),
                color: AppColors.warning,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Atenção: 2 slots de planos recorrentes foram liberados',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Quadra 1 — Ter 20h (Time Leões) • Campo Society — Qui 19h (Pelada Quinta)',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                  ],
                ),
              ),
              AppButton.outline(
                label: 'Ver planos',
                width: 160,
                height: AppSizes.buttonHeightSmall,
                onPressed: () => context.go(AppRoutes.recurringPlans),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReservationTable(List<Reservation> reservations) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1.2),
        1: FlexColumnWidth(1.5),
        2: FlexColumnWidth(1.5),
        3: FlexColumnWidth(1),
        4: FlexColumnWidth(1),
        5: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Horário', style: AppTextStyles.labelSmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Quadra', style: AppTextStyles.labelSmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Responsável', style: AppTextStyles.labelSmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Canal', style: AppTextStyles.labelSmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Status', style: AppTextStyles.labelSmall),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Ação', style: AppTextStyles.labelSmall),
            ),
          ],
        ),
        ...reservations.map(
          (r) => TableRow(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  '${r.startTime}–${r.endTime}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(r.courtId ?? '—', style: AppTextStyles.bodyMedium),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  r.bookerSnapshot.name,
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: ChannelBadge(channel: r.channel),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: StatusBadge(status: r.status),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextButton(
                  onPressed: () {},
                  child: const Text('Ver'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool isPositive;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(label, style: AppTextStyles.bodySmall),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(value, style: AppTextStyles.statNumber),
            const SizedBox(height: AppSpacing.xs),
            Text(
              change,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPositive ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
