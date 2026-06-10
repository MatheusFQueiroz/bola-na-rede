import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class CourtsPage extends StatelessWidget {
  final String fieldId;

  const CourtsPage({super.key, required this.fieldId});

  @override
  Widget build(BuildContext context) {
    final courts = MockData.courts[fieldId] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Quadras', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Adicionar Quadra',
              icon: PhosphorIcons.plus(),
              width: 200,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          padding: EdgeInsets.zero,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('#')),
              DataColumn(label: Text('Nome')),
              DataColumn(label: Text('Modalidade')),
              DataColumn(label: Text('Superfície')),
              DataColumn(label: Text('Capacidade')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Ações')),
            ],
            rows: courts.asMap().entries.map((entry) {
              final i = entry.key;
              final court = entry.value;
              return DataRow(cells: [
                DataCell(Text('${i + 1}')),
                DataCell(Text(court.name, style: AppTextStyles.bodyMedium)),
                DataCell(Text(court.modality.name.toUpperCase())),
                DataCell(Text(court.surface?.name ?? '—')),
                DataCell(Text('${court.capacity}v${court.capacity}')),
                DataCell(
                  Container(
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
