import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = GoRouterState.of(context).pathParameters['id']!;
    return ref.watch(matchDetailProvider(id)).when(
          data: (match) => _buildPage(context, ref, match),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            appBar: AppGradientAppBar(
                title: 'Detalhes da Partida', showBackButton: true),
            body: const Center(
                child: Text('Não foi possível carregar a partida.')),
          ),
        );
  }

  Widget _buildPage(BuildContext context, WidgetRef ref, Match match) {
    final myUserId = ref.watch(authViewModelProvider).value?.userId ?? '';
    final iAmA = match.teamAId == myUserId;
    final sport = _sportLabel(match.sport);
    final date = formatDate(match.scheduledDate);
    final badgeType = _badgeFor(match.status);
    final isCompleted = match.status == MatchStatus.completed;
    final isActive = match.status == MatchStatus.scheduled ||
        match.status == MatchStatus.inProgress;

    final myGoals = iAmA ? match.playerAGoals : match.playerBGoals;
    final theirGoals = iAmA ? match.playerBGoals : match.playerAGoals;
    final myAssists = iAmA ? match.playerAAssists : match.playerBAssists;
    final theirAssists = iAmA ? match.playerBAssists : match.playerAAssists;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
        title: 'Partida de $sport',
        showBackButton: true,
        actions: [AppBadge(type: badgeType)],
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(children: [
            _buildVsCard(myGoals, theirGoals, sport, date, isCompleted),
            const SizedBox(height: AppSpacing.md),
            if (isCompleted && myGoals != null)
              _buildStatsCard(
                  myGoals, theirGoals!, myAssists, theirAssists, iAmA),
            if (isCompleted && myGoals != null)
              const SizedBox(height: AppSpacing.md),
            _buildInfoCard(match),
          ]),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildFooter(context, ref, match, isActive, isCompleted),
        ),
      ]),
    );
  }

  Widget _buildVsCard(
    int? myGoals,
    int? theirGoals,
    String sport,
    String date,
    bool isCompleted,
  ) {
    return AppCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            const AppTeamAvatar(
                initials: 'EU', color: AppColors.avatarGreen, size: 56),
            const SizedBox(height: AppSpacing.sm),
            const Text('Eu', style: AppTextStyles.titleSmall),
          ]),
          Column(children: [
            if (isCompleted && myGoals != null && theirGoals != null)
              Text(
                '$myGoals – $theirGoals',
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              )
            else
              Text('VS',
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.textSecondary)),
            Text(sport,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDisabled)),
          ]),
          Column(children: [
            const AppTeamAvatar(
                initials: 'ADV', color: AppColors.avatarBlue, size: 56),
            const SizedBox(height: AppSpacing.sm),
            const Text('Adversário', style: AppTextStyles.titleSmall),
          ]),
        ]),
        const Divider(height: AppSpacing.xl),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
          Text(' $date',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildStatsCard(
    int myGoals,
    int theirGoals,
    int? myAssists,
    int? theirAssists,
    bool iAmA,
  ) {
    final resultLabel = myGoals > theirGoals
        ? 'VITÓRIA'
        : myGoals < theirGoals
            ? 'DERROTA'
            : 'EMPATE';
    final resultColor = myGoals > theirGoals
        ? AppColors.avatarGreen
        : myGoals < theirGoals
            ? AppColors.error
            : AppColors.textSecondary;

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Resultado', style: AppTextStyles.titleSmall),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: resultColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: Text(resultLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: resultColor)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _statTile('Gols', '$myGoals', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _statTile('Assist.', '${myAssists ?? 0}', AppColors.avatarTeal),
          const Spacer(),
          const Text('Eu    ×    Adv',
              style: TextStyle(
                  color: AppColors.textDisabled,
                  fontSize: 11)),
          const Spacer(),
          _statTile('Gols', '$theirGoals', AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          _statTile('Assist.', '${theirAssists ?? 0}', AppColors.avatarTeal),
        ]),
      ]),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: color)),
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }

  Widget _buildInfoCard(Match match) {
    final createdAt = formatDate(match.createdAt);
    return AppCard(
      child: Column(children: [
        _infoRow(PhosphorIcons.soccerBall(), 'Modalidade',
            _sportLabel(match.sport)),
        const Divider(),
        _infoRow(PhosphorIcons.calendar(), 'Data', createdAt),
        const Divider(),
        _infoRow(PhosphorIcons.hash(), 'ID do jogo',
            match.id.substring(0, 8).toUpperCase()),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Icon(icon, size: AppSizes.iconMd, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Text('$label: ',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        Text(value,
            style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildFooter(
    BuildContext context,
    WidgetRef ref,
    Match match,
    bool isActive,
    bool isCompleted,
  ) {
    if (isActive) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration:
            BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.modal),
        child: AppButton.primary(
          label: 'Registrar Resultado',
          icon: PhosphorIcons.trophy(),
          height: AppSizes.buttonHeightSmall,
          onPressed: () =>
              context.push(AppRoutes.registerResultOf(match.id)),
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration:
            BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.modal),
        child: Row(children: [
          Expanded(
            child: AppButton.outline(
              label: 'Disputar',
              icon: PhosphorIcons.warning(),
              height: AppSizes.buttonHeightSmall,
              onPressed: () => _dispute(context, ref, match.id),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton.primary(
              label: 'Confirmar',
              icon: PhosphorIcons.check(),
              height: AppSizes.buttonHeightSmall,
              onPressed: () => _confirm(context, ref, match.id),
            ),
          ),
        ]),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _confirm(
      BuildContext context, WidgetRef ref, String gameId) async {
    try {
      await ref.read(matchRepositoryProvider).confirmResult(gameId);
      ref.invalidate(matchDetailProvider(gameId));
      ref.invalidate(matchListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resultado confirmado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível confirmar.')),
      );
    }
  }

  Future<void> _dispute(
      BuildContext context, WidgetRef ref, String gameId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disputar resultado'),
        content: const Text(
            'Tem certeza que deseja disputar este resultado? O jogo será revisado.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Disputar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(matchRepositoryProvider).disputeResult(gameId);
      ref.invalidate(matchDetailProvider(gameId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Disputa registrada.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível disputar.')),
      );
    }
  }

  AppBadgeType _badgeFor(MatchStatus status) => switch (status) {
        MatchStatus.scheduled => AppBadgeType.waiting,
        MatchStatus.inProgress => AppBadgeType.confirmed,
        MatchStatus.completed => AppBadgeType.closed,
        MatchStatus.cancelled => AppBadgeType.closed,
        MatchStatus.noShow => AppBadgeType.closed,
      };

  String _sportLabel(String? sport) => switch (sport) {
        'futsal' => 'Futsal',
        'society' => 'Society',
        'campo' => 'Campo',
        _ => 'Futebol',
      };
}
