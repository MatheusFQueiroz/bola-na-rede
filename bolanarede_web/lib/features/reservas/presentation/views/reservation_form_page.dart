import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReservationFormPage extends StatelessWidget {
  const ReservationFormPage({super.key});

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
              child: Text('Nova Reserva', style: AppTextStyles.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulário (60%)
            Expanded(
              flex: 3,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dados do Horário',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    AppInput(label: 'Campo *'),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(label: 'Quadra *'),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(label: 'Data *'),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(child: AppInput(label: 'Início *')),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(child: AppInput(label: 'Fim *')),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'R\$ 120,00 / hora • 1h = R\$ 120,00',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text(
                      'Dados do Cliente',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    AppInput(label: 'Nome *'),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Telefone *',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    const Text(
                      'Canal de Origem',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    AppInput(label: 'Canal *'),
                    const SizedBox(height: AppSpacing.lg),
                    AppInput(
                      label: 'Notas internas',
                      hint: 'Observações sobre esta reserva...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),
            // Resumo (40%)
            Expanded(
              flex: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumo da Reserva',
                      style: AppTextStyles.titleSmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    _summaryRow(
                      PhosphorIcons.calendarBlank(),
                      'Terça, 10/06/2026',
                    ),
                    _summaryRow(
                      PhosphorIcons.clock(),
                      '20:00 – 21:00 (1h)',
                    ),
                    _summaryRow(
                      PhosphorIcons.soccerBall(),
                      'Arena / Quadra 1',
                    ),
                    _summaryRow(
                      PhosphorIcons.user(),
                      'João Silva',
                    ),
                    _summaryRow(
                      PhosphorIcons.whatsappLogo(),
                      'WhatsApp',
                    ),
                    const Divider(height: AppSpacing.xl),
                    Text(
                      'Regra: Noturno',
                      style: AppTextStyles.bodySmall,
                    ),
                    Text(
                      'R\$ 120,00/h × 1h',
                      style: AppTextStyles.bodySmall,
                    ),
                    const Divider(height: AppSpacing.xl),
                    const Text(
                      'TOTAL: R\$ 120,00',
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton.primary(
                      label: 'Criar Reserva',
                      onPressed: () => context.go('/dashboard/reservations'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/dashboard/reservations'),
                        child: const Text('Cancelar'),
                      ),
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

  Widget _summaryRow(IconData icon, String text) {
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
