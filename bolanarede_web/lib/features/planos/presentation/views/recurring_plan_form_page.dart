import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class RecurringPlanFormPage extends StatelessWidget {
  const RecurringPlanFormPage({super.key});

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
              child: Text('Novo Plano Recorrente', style: AppTextStyles.titleLarge),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppInput(label: 'Campo *'),
              const SizedBox(height: AppSpacing.lg),
              AppInput(label: 'Quadra *'),
              const SizedBox(height: AppSpacing.xxl),
              const Text('Responsável', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              AppInput(label: 'Nome *'),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Telefone *',
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text('Recorrência', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              AppInput(label: 'Dia da semana *'),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: AppInput(label: 'Horário início *')),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: AppInput(label: 'Horário fim *')),
                ],
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text('Financeiro', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              AppInput(
                label: 'Preço por slot (R\$) *',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Taxa de plataforma (%)',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Text('Configurações', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              AppInput(
                label: 'Horas antes para liberação automática *',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: AppInput(label: 'Válido a partir de *')),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(child: AppInput(label: 'Válido até (opcional)')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            AppButton.outline(
              label: 'Cancelar',
              width: 140,
              onPressed: () => context.go('/dashboard/recurring-plans'),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppButton.primary(
                label: 'Criar plano',
                onPressed: () => context.go('/dashboard/recurring-plans'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
