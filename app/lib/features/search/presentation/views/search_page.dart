import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/presentation/viewmodels/search_viewmodel.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});
  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  int _tabIndex = 0;
  String _filter = 'Perto de mim';
  final _tabs = ['Partidas', 'Times'];
  final _filters = ['Perto de mim', 'Hoje', 'Esta semana', 'Aberto'];
  final _searchController = TextEditingController();

  final _colors = [
    AppColors.avatarGreen,
    AppColors.avatarBlue,
    AppColors.avatarRed,
    AppColors.avatarOrange,
    AppColors.avatarPurple,
    AppColors.avatarTeal,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchViewModelProvider.notifier).search('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        _buildTabs(),
        _buildFilters(),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader() {
    return Container(
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
                child: Text('Buscar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 48),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) =>
                    ref.read(searchViewModelProvider.notifier).search(v),
                decoration: InputDecoration(
                  hintText: 'Buscar partidas ou times...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                      color: AppColors.textSecondary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(PhosphorIcons.x(),
                              color: AppColors.textSecondary, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(searchViewModelProvider.notifier)
                                .clear();
                            ref
                                .read(searchViewModelProvider.notifier)
                                .search('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: AppColors.surface,
      child: Column(children: [
        Row(
          children: List.generate(
              _tabs.length,
              (i) => Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _tabIndex = i),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _tabIndex == i
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(_tabs[i],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _tabIndex == i
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: _tabIndex == i
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontSize: 14,
                            )),
                      ),
                    ),
                  )),
        ),
        const Divider(height: 1),
      ]),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) => AppFilterChip(
          label: _filters[i],
          selected: _filter == _filters[i],
          onTap: () => setState(() => _filter = _filters[i]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final vm = ref.watch(searchViewModelProvider);

    if (vm.status == SearchStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.status == SearchStatus.error) {
      return Center(child: Text(vm.error ?? 'Erro'));
    }

    if (_tabIndex == 0) return _buildMatchList(vm.matches);
    return _buildTeamList(vm.teams);
  }

  Widget _buildMatchList(List<Match> matches) {
    if (matches.isEmpty) return _buildEmpty('Nenhuma partida encontrada');

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: matches.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _matchCard(matches[i]),
    );
  }

  Widget _matchCard(Match match) {
    final teamA = match.teamASnapshot?.name ?? 'Time';
    final initialsA = teamA.substring(0, 2).toUpperCase();
    final field = match.fieldSnapshot?.name ?? 'Local a definir';
    final address = match.fieldSnapshot?.address ?? '';
    final date =
        '${match.scheduledDate.day.toString().padLeft(2, '0')}/${match.scheduledDate.month.toString().padLeft(2, '0')}/${match.scheduledDate.year}';

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AppBadge(type: AppBadgeType.open),
          const Spacer(),
          Text('Amistoso',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          AppTeamAvatar(
              initials: initialsA, color: AppColors.avatarGreen, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Text(teamA, style: AppTextStyles.titleSmall),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('VS',
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700)),
          ),
          Text('?',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textDisabled)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
          Text(
              ' $date  ${match.scheduledTimeStart} – ${match.scheduledTimeEnd}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        Row(children: [
          Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
          Text(' $field  $address',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const Divider(height: AppSpacing.xl),
        AppButton.outline(
          label: 'Propor horario',
          height: AppSizes.buttonHeightSmall,
          onPressed: () => context.push(AppRoutes.matchDetail),
        ),
      ]),
    );
  }

  Widget _buildTeamList(List<Team> teams) {
    if (teams.isEmpty) return _buildEmpty('Nenhum time encontrado');

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, i) => _teamCard(teams[i], i),
    );
  }

  Widget _teamCard(Team team, int index) {
    final initials = team.name.substring(0, 2).toUpperCase();
    final color = _colors[index % _colors.length];

    return AppCard(
      child: Row(children: [
        AppTeamAvatar(initials: initials, color: color, size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(team.name, style: AppTextStyles.titleSmall),
            Text(team.city,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        AppButtonSmall(
          label: 'Ver time',
          filled: false,
          onPressed: () {},
        ),
      ]),
    );
  }

  Widget _buildEmpty(String message) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(PhosphorIcons.magnifyingGlass(),
            size: 48, color: AppColors.textDisabled),
        const SizedBox(height: AppSpacing.md),
        Text(message, style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Tente outro termo',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}
