import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReservationDetailPage extends StatelessWidget {
  final String reservationId;

  const ReservationDetailPage({super.key, required this.reservationId});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(PhosphorIcons.arrowLeft()),
              onPressed: () => context.go('/dashboard/reservations'),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Detalhe da Reserva',
                style: AppTextStyles.titleLarge,
              ),
            ),
            AppButton.outline(
              label: 'Editar',
              icon: PhosphorIcons.pencilSimple(),
              width: 120,
              onPressed: () {},
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info da reserva
            Expanded(
              flex: 3,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informações da Reserva',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _infoRow(
                      PhosphorIcons.calendarBlank(),
                      '09/06/2026 (Terça)',
                    ),
                    _infoRow(PhosphorIcons.clock(), '20:00 – 21:00'),
                    _infoRow(PhosphorIcons.soccerBall(), 'Arena BolaNaRede'),
                    _infoRow(PhosphorIcons.soccerBall(), 'Quadra 1'),
                    _infoRow(PhosphorIcons.whatsappLogo(), 'Canal: WhatsApp'),
                    const Divider(height: AppSpacing.xl),
                    const Text(
                      'Pagamento',
                      style: AppTextStyles.titleSmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _infoRow(
                      PhosphorIcons.currencyCircleDollar(),
                      'Valor: R\$ 120,00',
                    ),
                    _infoRow(
                      PhosphorIcons.receipt(),
                      'Taxa plataforma: R\$ 7,20 (6%)',
                    ),
                    _infoRow(
                      PhosphorIcons.money(),
                      'Valor líquido: R\$ 112,80',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Cliente + Status
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cliente',
                          style: AppTextStyles.titleSmall,
                        ),
                        const Divider(height: AppSpacing.xl),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary,
                              child: Text(
                                'JS',
                                style: TextStyle(
                                  color: AppColors.textOnPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'João Silva',
                                  style: AppTextStyles.bodyMedium,
                                ),
                                Text(
                                  '(41) 99999-9999',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Text(
                              'CONFIRMADO',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Criado em: 05/06 às 14:32',
                          style: AppTextStyles.bodySmall,
                        ),
                        Text(
                          'Confirmado em: 05/06 às 14:35',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}
