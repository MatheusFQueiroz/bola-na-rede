import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class FieldCatalogPage extends ConsumerStatefulWidget {
  const FieldCatalogPage({super.key});

  @override
  ConsumerState<FieldCatalogPage> createState() => _FieldCatalogPageState();
}

class _FieldCatalogPageState extends ConsumerState<FieldCatalogPage> {
  String _selectedFilter = 'Perto de mim';
  final _filters = ['Perto de mim', 'Society', 'Futsal', 'Salao', 'Disponivel hoje'];

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft(),
                        color: AppColors.textOnPrimary),
                    onPressed: () => context.pop(),
                  ),
                  const Expanded(
                    child: Text('Campos Proximo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600)),
                  ),
                  TextButton.icon(
                    onPressed: () => showComingSoon(context),
                    icon: Icon(PhosphorIcons.mapTrifold(),
                        color: AppColors.textOnPrimary, size: 18),
                    label: const Text('Mapa',
                        style: TextStyle(color: AppColors.textOnPrimary)),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar campo...',
                      prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                          color: AppColors.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: _filters.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => AppFilterChip(
              label: _filters[i],
              selected: _selectedFilter == _filters[i],
              onTap: () =>
                  setState(() => _selectedFilter = _filters[i]),
            ),
          ),
        ),
        Expanded(
          child: fieldsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Nao foi possivel carregar os campos.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
            data: (fields) => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: fields.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => _fieldCard(fields[i]),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _fieldCard(Field field) {
    final location = field.street ?? field.city;
    return AppCard(
      onTap: () => context.push(AppRoutes.fieldDetailOf(field.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Stack(children: [
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.md)),
            ),
            child: Center(
              child: Icon(PhosphorIcons.soccerBall(),
                  size: 64, color: AppColors.primaryBorder),
            ),
          ),
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: field.status == FieldStatus.active
                    ? AppColors.primarySurface
                    : AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                field.status == FieldStatus.active ? 'DISPONIVEL' : 'INDISPONIVEL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: field.status == FieldStatus.active
                      ? AppColors.primary
                      : AppColors.error,
                ),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(field.name, style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Icon(PhosphorIcons.mapPin(),
                  size: 14, color: AppColors.primary),
              Expanded(
                child: Text(
                  ' $location  ${field.city}',
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.sm),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              const Spacer(),
              AppButtonSmall(
                label: 'Ver mais',
                filled: false,
                onPressed: () =>
                    context.push(AppRoutes.fieldDetailOf(field.id)),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}
