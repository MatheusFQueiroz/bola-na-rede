import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/campos/domain/entities/field.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldsListPage extends StatelessWidget {
  const FieldsListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fields = MockData.fields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Meus Campos', style: AppTextStyles.titleLarge),
            ),
            AppButton.primary(
              label: '+ Cadastrar Campo',
              icon: PhosphorIcons.plus(),
              width: 200,
              onPressed: () => context.go(AppRoutes.fieldNew),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (fields.isEmpty)
          EmptyState(
            icon: PhosphorIcons.soccerBall(),
            title: 'Você ainda não tem campos cadastrados',
            description:
                'Cadastre seu primeiro campo para começar a gerenciar suas reservas.',
            actionLabel: 'Cadastrar meu primeiro campo',
            onAction: () => context.go(AppRoutes.fieldNew),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.85,
            ),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              final courts = MockData.courts[field.id] ?? [];
              return _FieldCard(
                field: field,
                courtCount: courts.length,
                onTap: () => context.go('/dashboard/fields/${field.id}'),
              );
            },
          ),
      ],
    );
  }
}

class _FieldCard extends StatelessWidget {
  final Field field;
  final int courtCount;
  final VoidCallback onTap;

  const _FieldCard({
    required this.field,
    required this.courtCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Foto placeholder
          Stack(
            children: [
              Container(
                height: 140,
                decoration: const BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                ),
                child: Center(
                  child: Icon(
                    PhosphorIcons.soccerBall(),
                    size: 48,
                    color: AppColors.primaryBorder,
                  ),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: field.status.name == 'active'
                        ? AppColors.primarySurface
                        : AppColors.errorSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    field.status.name == 'active' ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: field.status.name == 'active'
                          ? AppColors.primary
                          : AppColors.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(field.name, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Icon(
                      PhosphorIcons.mapPin(),
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${field.city}, ${field.state}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Text(
                      '⚽ $courtCount quadras',
                      style: AppTextStyles.labelSmall,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      '🏷️ Plano ${field.plan.name}',
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Divider(),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: onTap,
                        child: const Text('Ver detalhes'),
                      ),
                    ),
                    PopupMenuButton<String>(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Editar campo'),
                        ),
                        const PopupMenuItem(
                          value: 'courts',
                          child: Text('Gerenciar quadras'),
                        ),
                        const PopupMenuItem(
                          value: 'pricing',
                          child: Text('Configurar preços'),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          context.go('/dashboard/fields/${field.id}/edit');
                        } else if (value == 'courts') {
                          context.go('/dashboard/fields/${field.id}/courts');
                        } else if (value == 'pricing') {
                          context.go('/dashboard/fields/${field.id}/pricing');
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
