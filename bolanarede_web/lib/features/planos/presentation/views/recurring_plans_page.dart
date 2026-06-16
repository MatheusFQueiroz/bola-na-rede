import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class RecurringPlansPage extends StatelessWidget {
  const RecurringPlansPage({super.key});

  @override
  Widget build(BuildContext context) {
    final plans = MockData.recurringPlans;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Planos Recorrentes', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Novo Plano',
              icon: PhosphorIcons.plus(),
              width: 160,
              onPressed: () => context.go(AppRoutes.recurringPlanNew),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (plans.isEmpty)
          EmptyState(
            icon: PhosphorIcons.arrowsClockwise(),
            title: 'Nenhum plano recorrente',
            description:
                'Crie planos de horário fixo semanal para seus clientes frequentes.',
            actionLabel: 'Criar primeiro plano',
            onAction: () => context.go(AppRoutes.recurringPlanNew),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 1.8,
            ),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final dayName = [
                'Domingo',
                'Segunda',
                'Terça',
                'Quarta',
                'Quinta',
                'Sexta',
                'Sábado',
              ][plan.dayOfWeek];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          PhosphorIcons.arrowsClockwise(),
                          size: 20,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            plan.ownerSnapshot.displayName,
                            style: AppTextStyles.titleSmall,
                          ),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'view',
                              child: Text('Ver detalhes'),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Editar'),
                            ),
                          ],
                          onSelected: (v) {
                            if (v == 'view') {
                              context.go(
                                '/dashboard/recurring-plans/${plan.id}',
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Toda $dayName, ${plan.startTime} – ${plan.endTime}',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Arena / Quadra 1',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'R\$ ${plan.pricePerSlot.toStringAsFixed(0)}/semana',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '6% taxa',
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Divider(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => context.go(
                            '/dashboard/recurring-plans/${plan.id}',
                          ),
                          child: const Text('Ver detalhes'),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Editar'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
