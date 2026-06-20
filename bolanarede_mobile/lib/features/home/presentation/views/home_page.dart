import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/home/presentation/viewmodels/home_viewmodel.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/date_utils.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ref.watch(homeProvider).when(
            data: (data) => _buildBody(context, ref, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(
              child: Text('Não foi possível carregar.'),
            ),
          ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, HomeData data) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, ref, data)),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (data.nextMatch != null) ...[
                _buildNextMatch(context, data.nextMatch!),
                const SizedBox(height: AppSpacing.md),
              ],
              if (data.pendingRequest != null) ...[
                _buildPendingRequest(context, ref, data.pendingRequest!),
                const SizedBox(height: AppSpacing.md),
              ],
              _buildQuickActions(context),
              const SizedBox(height: AppSpacing.md),
              _buildRanking(context, ref),
              const SizedBox(height: AppSpacing.md),
              if (data.myTeam != null) _buildMyTeam(context, data),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, HomeData data) {
    final user = ref.watch(authViewModelProvider).value;
    final name = user?.displayName ?? 'Jogador';

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: Column(children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
                color: AppColors.primaryLight, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(initials(name, max: 1),
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bem-vindo de volta,',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textOnPrimary)),
            Text(name,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ]),
          const Spacer(),
          Icon(PhosphorIcons.mapPin(),
              color: AppColors.textOnPrimary, size: 14),
          Text(' ${user?.city ?? 'Curitiba'}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textOnPrimary)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          _statCard(PhosphorIcons.trophy(), '${data.myRank}', 'Lugar'),
          const SizedBox(width: AppSpacing.sm),
          _statCard(PhosphorIcons.users(), '${data.playerCount}', 'Jogadores'),
          const SizedBox(width: AppSpacing.sm),
          _statCard(PhosphorIcons.lightning(), '${data.winStreak}', 'Vitorias'),
        ]),
      ]),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Icon(icon, color: AppColors.textOnPrimary, size: AppSizes.iconMd),
          const SizedBox(height: AppSpacing.xs),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 22)),
          Text(label,
              style: TextStyle(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                  fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildNextMatch(BuildContext context, Match match) {
    final teamA = match.teamASnapshot?.name ?? 'Time A';
    final teamB = match.teamBSnapshot?.name ?? 'Time B';
    final initialsA = initials(teamA);
    final initialsB = initials(teamB);
    final field = match.fieldSnapshot?.name ?? 'Local a definir';
    final date = formatDate(match.scheduledDate);

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Proxima Partida',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          const AppBadge(type: AppBadgeType.confirmed),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            AppTeamAvatar(
                initials: initialsA, color: AppColors.avatarGreen, size: 48),
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
                initials: initialsB, color: AppColors.avatarBlue, size: 48),
            const SizedBox(height: AppSpacing.xs),
            Text(teamB, style: AppTextStyles.labelMedium),
          ]),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
          Text(' $date',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.md),
          Icon(PhosphorIcons.clock(), size: 14, color: AppColors.primary),
          Text(' ${match.scheduledTimeStart}',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
          Text(' $field',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        AppButton.outline(
          label: 'Ver detalhes',
          height: AppSizes.buttonHeightSmall,
          onPressed: () => context.push(AppRoutes.matchDetailOf(match.id)),
        ),
      ]),
    );
  }

  Widget _buildPendingRequest(BuildContext context, WidgetRef ref, Match match) {
    final sport = match.sport ?? 'futebol';
    final sportLabel = switch (sport) {
      'futsal' => 'Futsal',
      'society' => 'Society',
      'campo' => 'Campo',
      _ => 'Futebol',
    };

    return AppCard(
      border: const Border(
          left: BorderSide(color: AppColors.warningIcon, width: 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warningIcon.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(PhosphorIcons.clock(),
                color: AppColors.warningIcon, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Buscando adversário…',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text('Na fila para uma partida de $sportLabel',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        AppButton.outline(
          label: 'Cancelar solicitação',
          icon: PhosphorIcons.x(),
          height: AppSizes.buttonHeightSmall,
          onPressed: () => _cancelRequest(context, ref, match.id),
        ),
      ]),
    );
  }

  Future<void> _cancelRequest(
      BuildContext context, WidgetRef ref, String requestId) async {
    try {
      await ref.read(matchRepositoryProvider).cancelMatchRequest(requestId);
      ref.invalidate(homeProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitação cancelada.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível cancelar.')),
      );
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(children: [
          Expanded(
            child: AppCard(
              onTap: () => context.push(AppRoutes.search),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(PhosphorIcons.magnifyingGlass(),
                    color: AppColors.primary, size: AppSizes.iconLg),
                const SizedBox(height: AppSpacing.sm),
                const Text('Buscar partida', style: AppTextStyles.titleSmall),
                Text('Encontre adversarios',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ]),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppCard(
              onTap: () => context.push(AppRoutes.fieldCatalog),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Icon(PhosphorIcons.soccerBall(),
                    color: AppColors.primary, size: AppSizes.iconLg),
                const SizedBox(height: AppSpacing.sm),
                const Text('Reservar campo', style: AppTextStyles.titleSmall),
                Text('Veja campos proximos',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          onTap: () => context.push(AppRoutes.peladas),
          child: Row(children: [
            Icon(PhosphorIcons.users(),
                color: AppColors.primary, size: AppSizes.iconLg),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Peladas abertas', style: AppTextStyles.titleSmall),
              Text('Entre numa partida agora',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
            const Spacer(),
            Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
          ]),
        ),
      ],
    );
  }

  Widget _buildRanking(BuildContext context, WidgetRef ref) {
    final rankings = ref
        .watch(rankingProvider)
        .whenOrNull(data: (d) => d.playerRankings.take(3).toList());

    if (rankings == null || rankings.isEmpty) return const SizedBox();

    final colors = [
      AppColors.warningIcon,
      AppColors.avatarBlue,
      AppColors.avatarGreen,
    ];

    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Top Jogadores', style: AppTextStyles.titleSmall),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(AppRoutes.ranking),
            child: Text('Ver todos',
                style: AppTextStyles.link.copyWith(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        ...rankings.asMap().entries.map((e) {
          final player = e.value;
          final color = colors[e.key % colors.length];
          return Column(children: [
            if (e.key > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(children: [
                SizedBox(
                  width: 24,
                  child: Text('#${player.rank}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: player.rank == 1
                              ? AppColors.warningIcon
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppTeamAvatar(
                    initials: initials(player.name),
                    color: color,
                    size: 32,
                    fontSize: 12),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text('${player.matchesPlayed} jogos · ${player.goals} gols',
                            style: AppTextStyles.bodySmall),
                      ]),
                ),
                Text('${player.goals} gols',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]);
        }),
      ]),
    );
  }

  Widget _buildMyTeam(BuildContext context, HomeData data) {
    final team = data.myTeam!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryHorizontal,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(children: [
        Row(children: [
          AppTeamAvatar(
              initials: initials(team.name),
              color: AppColors.primaryLight,
              size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(team.name,
                  style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text(team.city,
                  style: TextStyle(
                      color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                      fontSize: 12)),
            ]),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.teamManageOf(team.id)),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textOnPrimary,
              side: const BorderSide(color: AppColors.textOnPrimary),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full)),
            ),
            child: const Text('Gerenciar', style: TextStyle(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _teamStat('Capitao', 'Voce'),
          _teamStat('Jogadores', '${data.playerCount}'),
          _teamStat('Serie', '${data.winStreak}V'),
        ]),
      ]),
    );
  }

  Widget _teamStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                  fontSize: 11)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ]),
      ),
    );
  }
}
