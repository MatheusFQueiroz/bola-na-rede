import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/app_main_nav_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  int _tabIndex = 0;
  String _filter = 'Perto de mim';
  final _tabs = ['Partidas', 'Peladas', 'Times'];
  final _filters = ['Perto de mim', 'Hoje', 'Esta semana', 'Aberto', 'Confirmado'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        // Header
        Container(
          decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: Row(children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.textOnPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Buscar', textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textOnPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar partidas, peladas ou times...',
                      prefixIcon: Icon(PhosphorIcons.magnifyingGlass(), color: AppColors.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
        // Tabs
        Container(
          color: AppColors.surface,
          child: Column(children: [
            Row(children: List.generate(_tabs.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _tabIndex = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(
                      color: _tabIndex == i ? AppColors.primary : Colors.transparent,
                      width: 2,
                    )),
                  ),
                  child: Text(_tabs[i], textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _tabIndex == i ? AppColors.primary : AppColors.textSecondary,
                        fontWeight: _tabIndex == i ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 14,
                      )),
                ),
              ),
            ))),
            const Divider(height: 1),
          ]),
        ),
        // Filtros
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => AppFilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),
        // Lista
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: _tabIndex == 2 ? _buildTeamCards() : _buildMatchCards(),
          ),
        ),
      ]),
      bottomNavigationBar: const AppMainNavBar(currentIndex: 1),
    );
  }

  List<Widget> _buildMatchCards() {
    return [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const AppBadge(type: AppBadgeType.open),
            const Spacer(),
            Text('Amistoso', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            const AppTeamAvatar(initials: 'FU', color: AppColors.avatarGreen, size: 40),
            const SizedBox(width: AppSpacing.sm),
            const Text('Furacao FC', style: AppTextStyles.titleSmall),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text('VS', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
            ),
            Text('?', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textDisabled)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
            Text(' Sab, 15/03/2025  18:00 – 19:00',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          Row(children: [
            Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
            Text(' Arena Society Xaxim  2,3 km',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          const Divider(height: AppSpacing.xl),
          AppButton.outline(
            label: 'Propor horario',
            height: AppSizes.buttonHeightSmall,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.matchDetail),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const AppBadge(type: AppBadgeType.open),
            const Spacer(),
            Text('Pelada', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          const Text('Pelada do Ze — Toda quinta!', style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
            Text(' Qui, 13/03/2025  20:00 – 21:00',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          Row(children: [
            Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
            Text(' Campo do Ze  Pinheirinho  4,1 km',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          Row(children: [
            Icon(PhosphorIcons.users(), size: 14, color: AppColors.primary),
            Text(' 8 / 14 jogadores confirmados',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: const LinearProgressIndicator(value: 0.57, minHeight: 6),
          ),
          const Divider(height: AppSpacing.xl),
          AppButton.primary(
            label: 'Entrar na Pelada',
            height: AppSizes.buttonHeightSmall,
            onPressed: () {},
          ),
        ]),
      ),
    ];
  }

  List<Widget> _buildTeamCards() {
    return [
      AppCard(
        child: Row(children: [
          const AppTeamAvatar(initials: 'D2', color: AppColors.avatarRed, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dragoes da ZL', style: AppTextStyles.titleSmall),
              Text('Sao Paulo  Intermediario',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text('46 jogos  Rating 1.240',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          AppButtonSmall(label: 'Ver time', filled: false, onPressed: () {}),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Row(children: [
          const AppTeamAvatar(initials: 'LS', color: AppColors.avatarBlue, size: 48),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Los Sharkis', style: AppTextStyles.titleSmall),
              Text('Sao Paulo  Iniciante',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              Text('12 jogos  Rating 980',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          AppButtonSmall(label: 'Ver time', filled: false, onPressed: () {}),
        ]),
      ),
    ];
  }
}
