import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class PricingPage extends StatelessWidget {
  final String fieldId;

  const PricingPage({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final rules = MockData.pricingRules[fieldId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Regras de Preço', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Nova Regra',
              icon: PhosphorIcons.plus(),
              width: 160,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          padding: EdgeInsets.zero,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Dias')),
              DataColumn(label: Text('Horário')),
              DataColumn(label: Text('Preço/h')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: rules.map((rule) {
              final days = rule.dayOfWeek == null
                  ? 'Todos'
                  : rule.dayOfWeek!
                      .map((d) => ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'][d])
                      .join(', ');
              return DataRow(cells: [
                DataCell(Text(rule.name, style: AppTextStyles.bodyMedium)),
                DataCell(Text(days, style: AppTextStyles.bodySmall)),
                DataCell(Text('${rule.startTime}–${rule.endTime}')),
                DataCell(
                  Text(
                    'R\$ ${rule.price.toStringAsFixed(2)}',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: rule.isActive
                          ? AppColors.primarySurface
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      rule.isActive ? 'Ativa' : 'Inativa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: rule.isActive
                            ? AppColors.primary
                            : AppColors.error,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(PhosphorIcons.pencilSimple(), size: 16),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          PhosphorIcons.trash(),
                          size: 16,
                          color: AppColors.error,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),
      ],
    );
  }
}
