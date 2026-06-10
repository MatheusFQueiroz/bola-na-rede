import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldFormPage extends StatelessWidget {
  final String? fieldId;

  const FieldFormPage({super.key, this.fieldId});

  bool get isEditing => fieldId != null;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isEditing ? 'Editar Campo' : 'Cadastrar Campo',
          style: AppTextStyles.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Campos > ${isEditing ? 'Editar' : 'Cadastrar'} campo',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Seção 1: Informações Básicas
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Informações Básicas', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              AppInput(
                label: 'Nome do campo *',
                hint: 'Ex: Arena do Grêmio',
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Descrição',
                hint: 'Descreva seu campo, diferenciais, estrutura...',
                maxLines: 3,
                maxLength: 500,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Telefone de contato *',
                      prefixIcon: PhosphorIcons.phone(),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppInput(
                      label: 'Email de contato',
                      prefixIcon: PhosphorIcons.envelope(),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'CEP *',
                      hint: '00000-000',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppInput(
                      label: 'Endereço completo *',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppInput(label: 'Cidade *'),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: AppInput(label: 'Estado *'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        PhosphorIcons.mapPin(),
                        size: 48,
                        color: AppColors.textDisabled,
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'Arraste o pin para ajustar coordenadas',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Seção 2: Fotos
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Fotos', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              const Text('Foto de capa', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                    color: AppColors.border,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      PhosphorIcons.upload(),
                      size: 32,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Arraste uma foto ou clique para selecionar',
                      style: AppTextStyles.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Formatos: JPG, PNG • Máx: 5MB',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        // Botões
        Row(
          children: [
            AppButton.outline(
              label: 'Cancelar',
              width: 140,
              onPressed: () => context.go('/dashboard/fields'),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppButton.primary(
                label: 'Salvar campo',
                onPressed: () => context.go('/dashboard/fields'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
