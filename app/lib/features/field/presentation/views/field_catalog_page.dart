import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class FieldCatalogPage extends StatefulWidget {
  const FieldCatalogPage({super.key});
  @override
  State<FieldCatalogPage> createState() => _FieldCatalogPageState();
}

class _FieldCatalogPageState extends State<FieldCatalogPage> {
  String _selectedFilter = 'Perto de mim';
  final _filters = ['Perto de mim', 'Society', 'Futsal', 'Salao', 'Disponivel hoje'];

  @override
  Widget build(BuildContext context) {
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
                          EdgeInsets.symmetric(vertical: 12),
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
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _fieldCard(
                id: 'field-001',
                name: 'Arena Society Xaxim',
                neighborhood: 'Xaxim',
                distance: '2,3 km',
                modalities: ['Society', 'Futsal'],
                price: 'R\$ 120/h',
                rating: 4.7,
                reviews: 38,
                available: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _fieldCard(
                id: 'field-002',
                name: 'Campo do Ze',
                neighborhood: 'Pinheirinho',
                distance: '4,1 km',
                modalities: ['Society'],
                price: 'R\$ 90/h',
                rating: 4.2,
                reviews: 21,
                available: true,
              ),
              const SizedBox(height: AppSpacing.md),
              _fieldCard(
                id: 'field-003',
                name: 'Futsal Center Portao',
                neighborhood: 'Portao',
                distance: '5,8 km',
                modalities: ['Futsal', 'Salao'],
                price: 'R\$ 80/h',
                rating: 4.9,
                reviews: 54,
                available: false,
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _fieldCard({
    required String id,
    required String name,
    required String neighborhood,
    required String distance,
    required List<String> modalities,
    required String price,
    required double rating,
    required int reviews,
    required bool available,
  }) {
    return AppCard(
      onTap: () => context.push(AppRoutes.fieldDetailOf(id)),
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
                color: available ? AppColors.primarySurface : AppColors.errorSurface,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                available ? 'DISPONIVEL' : 'LOTADO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: available ? AppColors.primary : AppColors.error,
                ),
              ),
            ),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.titleSmall),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Icon(PhosphorIcons.mapPin(),
                  size: 14, color: AppColors.primary),
              Text(' $neighborhood  $distance',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              children: modalities.map((m) => AppFilterChip(
                label: m, selected: false, onTap: () {})).toList(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [
              Text('A partir de $price',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: AppColors.primary)),
              const Spacer(),
              AppButtonSmall(
                label: 'Ver mais',
                filled: false,
                onPressed: () =>
                    context.push(AppRoutes.fieldDetailOf(id)),
              ),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Row(children: [
              Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: AppColors.warningIcon, size: 14),
              Text(' $rating  $reviews reservas',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
          ]),
        ),
      ]),
    );
  }
}
