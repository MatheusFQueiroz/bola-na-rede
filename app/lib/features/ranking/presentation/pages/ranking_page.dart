import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';
import '../viewmodels/ranking_viewmodel.dart';
import '../../domain/entities/ranking.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _tab = 0;
  String _filter = 'Geral';
  final _filters = ['Geral', 'Curitiba', 'Esta semana', 'Este mes'];

  final _colors = [
    AppColors.avatarBlue,
    AppColors.avatarRed,
    AppColors.avatarGreen,
    AppColors.avatarTeal,
    AppColors.avatarPurple,
    AppColors.avatarOrange,
    AppColors.avatarBlue,
    AppColors.avatarRed,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RankingViewModel>().loadRankings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        SizedBox(
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
        ),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildBody() {
    return Consumer<RankingViewModel>(
      builder: (_, vm, __) {
        if (vm.state == RankingViewState.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.state == RankingViewState.error) {
          return Center(child: Text(vm.error ?? 'Erro'));
        }

        final teams = vm.teamRankings;
        final players = vm.playerRankings;
        final top3 =
            _tab == 0 ? teams.take(3).toList() : players.take(3).toList();
        final rest =
            _tab == 0 ? teams.skip(3).toList() : players.skip(3).toList();

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _buildPodium(top3),
            const SizedBox(height: AppSpacing.md),
            _buildList(rest),
            const SizedBox(height: AppSpacing.md),
            _buildMyCard(vm),
          ],
        );
      },
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
                const Expanded(
                  child: Text('Ranking',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600)),
                ),
                Icon(PhosphorIcons.trophy(),
                    color: AppColors.textOnPrimary, size: AppSizes.iconLg),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  children: ['Times', 'Jogadores'].asMap().entries.map((e) {
                    final active = _tab == e.key;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _tab = e.key),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm),
                          decoration: BoxDecoration(
                            color:
                                active ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textOnPrimary,
                                fontWeight:
                                    active ? FontWeight.w700 : FontWeight.w400,
                                fontSize: 14,
                              )),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ])),
    );
  }

  Widget _buildPodium(List<dynamic> top3) {
    if (top3.length < 3) return const SizedBox();

    String getName(dynamic item) =>
        _tab == 0 ? (item as TeamRanking).name : (item as PlayerRanking).name;

    String getValue(dynamic item) => _tab == 0
        ? '${(item as TeamRanking).points} pts'
        : '${(item as PlayerRanking).goals} gols';

    int getRank(dynamic item) =>
        _tab == 0 ? (item as TeamRanking).rank : (item as PlayerRanking).rank;

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _podiumItem(top3[1], 52, getName, getValue, getRank),
            _podiumItem(top3[0], 72, getName, getValue, getRank),
            _podiumItem(top3[2], 44, getName, getValue, getRank),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(
      dynamic item,
      double size,
      String Function(dynamic) getName,
      String Function(dynamic) getValue,
      int Function(dynamic) getRank) {
    final rank = getRank(item);
    final name = getName(item);
    final value = getValue(item);
    final initials = name.substring(0, 2).toUpperCase();
    final color = _colors[(rank - 1) % _colors.length];

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (rank == 1)
        Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
            color: AppColors.warningIcon, size: 18),
      AppTeamAvatar(
          initials: initials,
          color: color,
          size: size,
          fontSize: size > 60 ? 20 : 14),
      const SizedBox(height: AppSpacing.xs),
      Text('$rank',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: rank == 1 ? 18 : 14,
              color:
                  rank == 1 ? AppColors.warningIcon : AppColors.textSecondary)),
      SizedBox(
        width: 80,
        child: Text(name,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis),
      ),
      Text(value,
          style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 13)),
    ]);
  }

  Widget _buildList(List<dynamic> items) {
    String getName(dynamic item) =>
        _tab == 0 ? (item as TeamRanking).name : (item as PlayerRanking).name;

    String getSub(dynamic item) => _tab == 0
        ? '${(item as TeamRanking).matchesPlayed} jogos'
        : '${(item as PlayerRanking).teamName} · ${(item as PlayerRanking).position}';

    String getValue(dynamic item) => _tab == 0
        ? '${(item as TeamRanking).points} pts'
        : '${(item as PlayerRanking).goals} gols';

    String getExtra(dynamic item) => _tab == 0
        ? (item as TeamRanking).goalDifference >= 0
            ? '+${(item as TeamRanking).goalDifference}'
            : '${(item as TeamRanking).goalDifference}'
        : '${(item as PlayerRanking).matchesPlayed} jogos';

    int getRank(dynamic item) =>
        _tab == 0 ? (item as TeamRanking).rank : (item as PlayerRanking).rank;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Classificacao completa', style: AppTextStyles.titleSmall),
          const Spacer(),
          Text('Temporada 2025',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        ...items.map((item) {
          final rank = getRank(item);
          final name = getName(item);
          final initials = name.substring(0, 2).toUpperCase();
          final color = _colors[(rank - 1) % _colors.length];

          return Column(children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(children: [
                SizedBox(
                    width: 28,
                    child: Text('#$rank',
                        style: AppTextStyles.bodySmall
                            .copyWith(fontWeight: FontWeight.w700))),
                AppTeamAvatar(
                    initials: initials, color: color, size: 32, fontSize: 11),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(name,
                          style: AppTextStyles.bodyMedium
                              .copyWith(fontWeight: FontWeight.w700)),
                      Text(getSub(item), style: AppTextStyles.bodySmall),
                    ])),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(getValue(item),
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                  Text(getExtra(item), style: AppTextStyles.bodySmall),
                ]),
              ]),
            ),
          ]);
        }),
      ]),
    );
  }

  Widget _buildMyCard(RankingViewModel vm) {
    if (_tab == 0) {
      final myTeam =
          vm.teamRankings.where((t) => t.id == 'team-001').firstOrNull;
      if (myTeam == null) return const SizedBox();

      return AppCard(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primary),
        child: Row(children: [
          const AppTeamAvatar(
              initials: 'FU', color: AppColors.avatarGreen, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(myTeam.name, style: AppTextStyles.titleSmall),
                Text('Sua posicao: #${myTeam.rank}  ${myTeam.points} pts',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ])),
        ]),
      );
    } else {
      final myPlayer =
          vm.playerRankings.where((p) => p.id == 'user-001').firstOrNull;
      if (myPlayer == null) return const SizedBox();

      return AppCard(
        color: AppColors.primarySurface,
        border: Border.all(color: AppColors.primary),
        child: Row(children: [
          const AppTeamAvatar(
              initials: 'CS', color: AppColors.avatarGreen, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(myPlayer.name, style: AppTextStyles.titleSmall),
                Text(
                    '#${myPlayer.rank}  ${myPlayer.goals} gols  '
                    '${myPlayer.matchesPlayed} jogos',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w600)),
              ])),
        ]),
      );
    }
  }
}
