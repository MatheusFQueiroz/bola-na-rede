import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/campos/domain/entities/field.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldsListPage extends StatefulWidget {
  const FieldsListPage({super.key});

  @override
  State<FieldsListPage> createState() => _FieldsListPageState();
}

class _FieldsListPageState extends State<FieldsListPage> {
  final _searchController = TextEditingController();

  String _searchQuery = '';
  FieldStatus? _statusFilter;
  FieldPlan? _planFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Field> get _filtered {
    var result = MockData.fields.toList();

    // Busca por nome ou cidade
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where(
            (f) =>
                f.name.toLowerCase().contains(q) ||
                f.city.toLowerCase().contains(q),
          )
          .toList();
    }

    // Filtro de status
    if (_statusFilter != null) {
      result = result.where((f) => f.status == _statusFilter).toList();
    }

    // Filtro de plano
    if (_planFilter != null) {
      result = result.where((f) => f.plan == _planFilter).toList();
    }

    return result;
  }

  bool get _hasActiveFilters =>
      _statusFilter != null ||
      _planFilter != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _statusFilter = null;
      _planFilter = null;
    });
  }

  String _statusLabel(FieldStatus s) {
    switch (s) {
      case FieldStatus.active:
        return 'Ativo';
      case FieldStatus.inactive:
        return 'Inativo';
      case FieldStatus.suspended:
        return 'Suspenso';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
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

        // Filtros
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Busca por nome ou cidade
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar por nome ou cidade...',
                        prefixIcon: Icon(
                          PhosphorIcons.magnifyingGlass(),
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  PhosphorIcons.x(),
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () => setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Filtro de status
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<FieldStatus?>(
                      value: _statusFilter,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os status'),
                        ),
                        ...FieldStatus.values.map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _statusFilter = v),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  // Filtro de plano
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<FieldPlan?>(
                      value: _planFilter,
                      decoration: InputDecoration(
                        labelText: 'Plano',
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.inputRadius,
                          borderSide:
                              const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('Todos os planos'),
                        ),
                        ...FieldPlan.values.map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.name.toUpperCase()),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _planFilter = v),
                    ),
                  ),

                  if (_hasActiveFilters) ...[
                    const SizedBox(width: AppSpacing.md),
                    AppButton.outline(
                      label: 'Limpar',
                      icon: PhosphorIcons.funnel(),
                      width: 120,
                      height: AppSizes.buttonHeightSmall,
                      onPressed: _clearFilters,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${filtered.length} campo(s) encontrado(s)',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),

        // Grid de campos ou estado vazio
        if (filtered.isEmpty)
          EmptyState(
            icon: PhosphorIcons.soccerBall(),
            title: _hasActiveFilters
                ? 'Nenhum campo encontrado'
                : 'Você ainda não tem campos cadastrados',
            description: _hasActiveFilters
                ? 'Tente ajustar os filtros de busca'
                : 'Cadastre seu primeiro campo para começar a gerenciar suas reservas.',
            actionLabel: _hasActiveFilters
                ? 'Limpar filtros'
                : 'Cadastrar meu primeiro campo',
            onAction: _hasActiveFilters
                ? _clearFilters
                : () => context.go(AppRoutes.fieldNew),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.lg,
              mainAxisSpacing: AppSpacing.lg,
              childAspectRatio: 0.75,
            ),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final field = filtered[index];
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
    final isActive = field.status == FieldStatus.active;

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
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
                // Badge de status
                Positioned(
                  top: AppSpacing.sm,
                  left: AppSpacing.sm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primarySurface
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                    child: Text(
                      isActive ? 'ATIVO' : field.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color:
                            isActive ? AppColors.primary : AppColors.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Informações
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
                        '⚽ $courtCount quadra(s)',
                        style: AppTextStyles.labelSmall,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        '🏷️ Plano ${field.plan.name.toUpperCase()}',
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
                            context.go(
                              '/dashboard/fields/${field.id}/edit',
                            );
                          } else if (value == 'courts') {
                            context.go(
                              '/dashboard/fields/${field.id}/courts',
                            );
                          } else if (value == 'pricing') {
                            context.go(
                              '/dashboard/fields/${field.id}/pricing',
                            );
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
      ),
    );
  }
}