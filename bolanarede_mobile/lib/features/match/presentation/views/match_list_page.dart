import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
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
                    ? _buildEmpty(context)
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) =>
                            _MatchCard(match: matches[i]),
                      ),
                loading: () => ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: 4,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, __) => const AppShimmerCard(),
                    ),
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
        icon: Icon(PhosphorIcons.magnifyingGlass(),
            color: AppColors.textOnPrimary),
        label: const Text('Buscar Partida',
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
              child: Icon(PhosphorIcons.magnifyingGlass(),
                  color: AppColors.textOnPrimary, size: AppSizes.iconLg),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(PhosphorIcons.soccerBall(),
            size: 64, color: AppColors.textDisabled),
        const SizedBox(height: AppSpacing.lg),
        const Text('Nenhuma partida ainda', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Busque um adversário para começar',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        AppButtonSmall(
          label: 'Buscar partida',
          filled: true,
          onPressed: () => context.push(AppRoutes.createMatch),
        ),
      ]),
    );
  }
}

class _MatchCard extends ConsumerStatefulWidget {
  const _MatchCard({required this.match});

  final Match match;

  @override
  ConsumerState<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<_MatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _scaleController;
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myUserId = ref.watch(authViewModelProvider).value?.userId ?? '';
    final iAmA = widget.match.teamAId == myUserId;
    final myGoals = iAmA ? widget.match.playerAGoals : widget.match.playerBGoals;
    final theirGoals = iAmA ? widget.match.playerBGoals : widget.match.playerAGoals;
    final sport = _sportLabel(widget.match.sport);
    final date = formatDate(widget.match.scheduledDate);
    final isCompleted = widget.match.status == MatchStatus.completed;

    final hasResult = isCompleted && myGoals != null && theirGoals != null;
    final resultLabel = hasResult ? _resultLabel(myGoals, theirGoals) : null;
    final resultColor = hasResult ? _resultColor(myGoals, theirGoals) : null;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _scaleController.reverse(),
        onTapUp: (_) {
          _scaleController.forward();
          context.push(AppRoutes.matchDetailOf(widget.match.id));
        },
        onTapCancel: () => _scaleController.forward(),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            boxShadow: AppShadows.card,
            border: hasResult
                ? Border(
                    left: BorderSide(
                      color: resultColor!,
                      width: 4,
                    ),
                  )
                : null,
          ),
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(sport,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
              if (hasResult) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: resultColor!.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(resultLabel!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: resultColor)),
                ),
              ],
              const Spacer(),
              Text(date,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: AppSpacing.md),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _playerColumn('EU', AppColors.avatarGreen),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: hasResult
                    ? Column(children: [
                        Text(
                          '$myGoals × $theirGoals',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                              letterSpacing: -1),
                        ),
                        const SizedBox(height: 2),
                        Text('gols',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.textDisabled)),
                      ])
                    : Text('VS',
                        style: AppTextStyles.titleLarge
                            .copyWith(color: AppColors.textDisabled)),
              ),
              _playerColumn('ADV', AppColors.avatarBlue),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _playerColumn(String label, Color color) {
    return Column(children: [
      AppTeamAvatar(initials: label, color: color, size: 44),
      const SizedBox(height: AppSpacing.xs),
      Text(label == 'EU' ? 'Eu' : 'Adversário',
          style: AppTextStyles.labelMedium),
    ]);
  }

  String _sportLabel(String? sport) => switch (sport) {
        'futsal' => 'Futsal',
        'society' => 'Society',
        'campo' => 'Campo',
        _ => 'Futebol',
      };

  String _resultLabel(int mine, int theirs) {
    if (mine > theirs) return 'VITÓRIA';
    if (mine < theirs) return 'DERROTA';
    return 'EMPATE';
  }

  Color _resultColor(int mine, int theirs) {
    if (mine > theirs) return AppColors.avatarGreen;
    if (mine < theirs) return AppColors.error;
    return AppColors.textSecondary;
  }
}
