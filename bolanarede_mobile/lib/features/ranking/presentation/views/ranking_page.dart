import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';
import 'package:bola_na_rede/features/ranking/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});
  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
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
        Expanded(
          child: ref.watch(rankingProvider).when(
                data: (data) => _buildBody(data),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Não foi possível carregar o ranking.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
        ),
      ]),
    );
  }

  Widget _buildBody(RankingData data) {
    final teams = data.teamRankings;
    final players = data.playerRankings;
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
        _buildMyCard(data),
      ],
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
                  color: Colors.white.withValues(alpha: 0.2),
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
                            color: active
                                ? AppColors.surface
                                : Colors.transparent,
                            borderRadius:
                                BorderRadius.circular(AppRadius.full),
                          ),
                          child: Text(e.value,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textOnPrimary,
                                fontWeight: active
                                    ? FontWeight.w700
                                    : FontWeight.w400,
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
    final color = _colors[(rank - 1) % _colors.length];

    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (rank == 1)
        Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
            color: AppColors.warningIcon, size: 18),
      AppTeamAvatar(
          initials: initials(name),
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

    String getSub(dynamic item) {
      if (_tab == 0) return '${(item as TeamRanking).matchesPlayed} jogos';
      final p = item as PlayerRanking;
      return '${p.teamName} · ${p.position}';
    }

    String getValue(dynamic item) => _tab == 0
        ? '${(item as TeamRanking).points} pts'
        : '${(item as PlayerRanking).goals} gols';

    String getExtra(dynamic item) {
      if (_tab != 0) return '${(item as PlayerRanking).matchesPlayed} jogos';
      final t = item as TeamRanking;
      return t.goalDifference >= 0 ? '+${t.goalDifference}' : '${t.goalDifference}';
    }

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
                    initials: initials(name),
                    color: color,
                    size: 32,
                    fontSize: 11),
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

  Widget _buildMyCard(RankingData data) {
    final myUserId = ref.watch(authViewModelProvider).value?.userId ?? '';

    if (_tab == 0) {
      return const SizedBox();
    }

    final myPlayer =
        data.playerRankings.where((p) => p.id == myUserId).firstOrNull;
    if (myPlayer == null) return const SizedBox();

    return AppCard(
      color: AppColors.primarySurface,
      border: Border.all(color: AppColors.primary),
      child: Row(children: [
        AppTeamAvatar(
            initials: initials(myPlayer.name),
            color: AppColors.avatarGreen,
            size: 40),
        const SizedBox(width: AppSpacing.md),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const Text('Minha posição', style: AppTextStyles.titleSmall),
              Text(
                  '#${myPlayer.rank}  ${myPlayer.goals} gols  '
                  '${myPlayer.assists} assist.  ${myPlayer.matchesPlayed} jogos',
                  style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600)),
            ])),
      ]),
    );
  }
}
