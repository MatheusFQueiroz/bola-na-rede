import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final customers = MockData.customers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Clientes', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Cadastrar Cliente',
              icon: PhosphorIcons.plus(),
              width: 200,
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
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Tipo')),
                  DataColumn(label: Text('Reservas')),
                  DataColumn(label: Text('Última visita')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: customers.map((c) {
                  final initials = c.displayName
                      .split(' ')
                      .take(2)
                      .map((w) => w[0])
                      .join()
                      .toUpperCase();
                  return DataRow(cells: [
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: AppColors.textOnPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.displayName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (c.contactPhone != null)
                                Text(
                                  c.contactPhone!,
                                  style: AppTextStyles.bodySmall,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        c.customerType.name.toUpperCase(),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    DataCell(Text('${c.totalBookings}')),
                    DataCell(
                      Text(
                        '${c.lastBookingAt.day.toString().padLeft(2, '0')}/${c.lastBookingAt.month.toString().padLeft(2, '0')}/${c.lastBookingAt.year}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    DataCell(
                      IconButton(
                        icon: Icon(PhosphorIcons.eye(), size: 16),
                        onPressed: () => context.go(
                          '/dashboard/customers/${c.id}',
                        ),
                      ),
                    ),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
