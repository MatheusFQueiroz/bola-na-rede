import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class RecurringPlanDetailPage extends StatelessWidget {
  final String planId;

  const RecurringPlanDetailPage({super.key, required this.planId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.arrowLeft()),
              onPressed: () => context.go('/dashboard/recurring-plans'),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Plano: Time Leões',
                style: AppTextStyles.titleLarge,
              ),
            ),
            AppButton.outline(
              label: 'Editar',
              width: 100,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.outline(
              label: 'Pausar',
              width: 100,
              onPressed: () {},
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.danger(
              label: 'Cancelar',
              width: 100,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informações', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              _infoRow('Campo:', 'Arena BolaNaRede / Quadra 1'),
              _infoRow('Recorrência:', 'Toda Terça-feira'),
              _infoRow('Horário:', '20:00 – 21:00'),
              _infoRow('Responsável:', 'Carlos Mendes (44) 99999-9999'),
              _infoRow('Válido de:', '01/05/2026 até indefinido'),
              _infoRow('Liberação automática:', '12h antes se não confirmado'),
              _infoRow('Valor:', 'R\$ 120,00/semana'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Próximas 8 semanas',
                  style: AppTextStyles.titleSmall,
                ),
              ),
              const Divider(height: 1),
              DataTable(
                columns: const [
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Ação')),
                ],
                rows: [
                  _slotRow('10/06 (Ter)', 'Confirmado', AppColors.success),
                  _slotRow('17/06 (Ter)', 'Aguardando', AppColors.warning),
                  _slotRow('24/06 (Ter)', 'Aguardando', AppColors.warning),
                  _slotRow('01/07 (Ter)', 'Aguardando', AppColors.warning),
                  _slotRow('08/07 (Ter)', 'Aguardando', AppColors.warning),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }

  DataRow _slotRow(String date, String status, Color color) {
    return DataRow(cells: [
      DataCell(Text(date, style: AppTextStyles.bodyMedium)),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
      DataCell(
        status == 'Aguardando'
            ? TextButton(
                onPressed: () {},
                child: const Text('Confirmar'),
              )
            : const Text('—'),
      ),
    ]);
  }
}
