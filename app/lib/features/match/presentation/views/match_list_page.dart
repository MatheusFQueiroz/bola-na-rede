import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class MatchListPage extends ConsumerWidget {
  const MatchListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(context),
        Expanded(
          child: ref.watch(matchListProvider).when(
                data: (matches) => matches.isEmpty
                    ? _buildEmpty()
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) =>
                            _matchCard(context, matches[i]),
                      ),
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    'Não foi possível carregar as partidas.',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createMatch),
        backgroundColor: AppColors.primary,
        icon: Icon(PhosphorIcons.plus(), color: AppColors.textOnPrimary),
        label: const Text('Nova Partida',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(children: [
            const Expanded(
              child: Text('Partidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () => context.push(AppRoutes.createMatch),
              child: Icon(PhosphorIcons.plus(),
                  color: AppColors.textOnPrimary, size: AppSizes.iconLg),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _matchCard(BuildContext context, Match match) {
    final teamA = match.teamASnapshot?.name ?? 'Time A';
    final teamB = match.teamBSnapshot?.name ?? 'Time B';
    final initialsA = initials(teamA);
    final initialsB = initials(teamB);
    final field = match.fieldSnapshot?.name ?? 'Local a definir';
    final date = formatDate(match.scheduledDate);

    final badgeType = match.status == MatchStatus.scheduled
        ? AppBadgeType.confirmed
        : AppBadgeType.closed;

    return AppCard(
      onTap: () => context.push(AppRoutes.matchDetailOf(match.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppBadge(type: badgeType),
          const Spacer(),
          Text(date,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            AppTeamAvatar(
                initials: initialsA, color: AppColors.avatarGreen, size: 40),
            const SizedBox(height: AppSpacing.xs),
            Text(teamA, style: AppTextStyles.labelMedium),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('VS',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Column(children: [
            AppTeamAvatar(
                initials: initialsB, color: AppColors.avatarBlue, size: 40),
            const SizedBox(height: AppSpacing.xs),
            Text(teamB, style: AppTextStyles.labelMedium),
          ]),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.clock(), size: 14, color: AppColors.primary),
          Text(' ${match.scheduledTimeStart} – ${match.scheduledTimeEnd}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
          Text(' $field',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(PhosphorIcons.soccerBall(),
            size: 64, color: AppColors.textDisabled),
        const SizedBox(height: AppSpacing.lg),
        const Text('Nenhuma partida ainda', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Crie sua primeira partida',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}
