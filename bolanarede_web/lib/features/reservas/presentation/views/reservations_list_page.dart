import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReservationsListPage extends StatelessWidget {
  const ReservationsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final reservations = MockData.reservations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Reservas', style: AppTextStyles.titleLarge),
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

        // Filtros
        AppCard(
          child: Row(
            children: [
              Expanded(
                child: AppInput(
                  label: '',
                  hint: 'Buscar cliente...',
                  prefixIcon: PhosphorIcons.magnifyingGlass(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 150,
                child: AppInput(label: '', hint: 'Status'),
              ),
              const SizedBox(width: AppSpacing.md),
              SizedBox(
                width: 150,
                child: AppInput(label: '', hint: 'Canal'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Tabela
        AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1100,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Data/Hora')),
                  DataColumn(label: Text('Campo/Quadra')),
                  DataColumn(label: Text('Cliente')),
                  DataColumn(label: Text('Canal')),
                  DataColumn(label: Text('Valor')),
                  DataColumn(label: Text('Pgto')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Ações')),
                ],
                rows: reservations.map((r) {
                  return DataRow(cells: [
                    DataCell(
                      Text(
                        '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')} ${r.startTime}–${r.endTime}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(Text('Arena / Quadra 1')),
                    DataCell(Text(r.bookerSnapshot.name)),
                    DataCell(ChannelBadge(channel: r.channel)),
                    DataCell(
                      Text(
                        'R\$ ${r.price.toStringAsFixed(0)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    DataCell(PaymentBadge(status: r.paymentStatus)),
                    DataCell(StatusBadge(status: r.status)),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(PhosphorIcons.eye(), size: 16),
                            onPressed: () => context.go(
                              '/dashboard/reservations/${r.id}',
                            ),
                          ),
                          IconButton(
                            icon: Icon(PhosphorIcons.pencilSimple(),
                              size: 16,
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
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Paginação
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.caretLeft()),
              onPressed: null,
            ),
            ...List.generate(3, (i) {
              final page = i + 1;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor:
                          page == 1 ? AppColors.primary : null,
                      foregroundColor:
                          page == 1 ? AppColors.textOnPrimary : null,
                    ),
                    child: Text('$page'),
                  ),
                ),
              );
            }),
            IconButton(
              icon: Icon(PhosphorIcons.caretRight()),
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}
