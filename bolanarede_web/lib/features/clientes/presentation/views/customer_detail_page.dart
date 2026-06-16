import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class CustomerDetailPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.arrowLeft()),
              onPressed: () => context.go('/dashboard/customers'),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text('João Silva', style: AppTextStyles.titleLarge),
            ),
            AppButton.outline(
              label: 'Editar',
              width: 100,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Nova reserva',
              icon: PhosphorIcons.plus(),
              width: 160,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                children: [
                  // Stats
                  Row(
                    children: [
                      _StatCard(value: '12', label: 'Reservas'),
                      const SizedBox(width: AppSpacing.lg),
                      _StatCard(value: 'R\$ 1.440', label: 'Total'),
                      const SizedBox(width: AppSpacing.lg),
                      _StatCard(value: 'Quadra 1', label: 'Favorita'),
                      const SizedBox(width: AppSpacing.lg),
                      _StatCard(value: 'Sábado', label: 'Dia pref.'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Histórico
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.lg),
                          child: Text(
                            'Histórico de Reservas',
                            style: AppTextStyles.titleSmall,
                          ),
                        ),
                        const Divider(height: 1),
                        DataTable(
                          columns: const [
                            DataColumn(label: Text('Data')),
                            DataColumn(label: Text('Quadra')),
                            DataColumn(label: Text('Duração')),
                            DataColumn(label: Text('Valor')),
                            DataColumn(label: Text('Status')),
                          ],
                          rows: [
                            _historyRow(
                              '09/06/26',
                              'Quadra 1',
                              '1h',
                              'R\$ 120',
                              'Confirmado',
                              AppColors.success,
                            ),
                            _historyRow(
                              '02/06/26',
                              'Society',
                              '1h',
                              'R\$ 150',
                              'Concluído',
                              AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            Expanded(
              flex: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notas do Campo',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    AppInput(
                      label: '',
                      hint: 'Prefere horário das 20h. Sempre pontual.',
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.primary(
                      label: 'Salvar notas',
                      height: AppSizes.buttonHeightSmall,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  DataRow _historyRow(
    String date,
    String court,
    String duration,
    String value,
    String status,
    Color color,
  ) {
    return DataRow(cells: [
      DataCell(Text(date, style: AppTextStyles.bodySmall)),
      DataCell(Text(court)),
      DataCell(Text(duration)),
      DataCell(Text(value, style: AppTextStyles.bodyMedium)),
      DataCell(
        Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;

  const _StatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        child: Column(
          children: [
            Text(value, style: AppTextStyles.statNumber),
            const SizedBox(height: AppSpacing.xs),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      ),
    );
  }
}
