import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Consumer;
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/ranking/presentation/viewmodels/ranking_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';
import 'package:bola_na_rede/features/home/presentation/viewmodels/home_viewmodel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().loadHome();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<HomeViewModel>(
        builder: (_, vm, __) {
          if (vm.state == HomeViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(vm)),
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    if (vm.nextMatch != null) ...[
                      _buildNextMatch(vm.nextMatch!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (vm.pendingRequest != null) ...[
                      _buildPendingRequest(vm.pendingRequest!),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    _buildQuickActions(),
                    const SizedBox(height: AppSpacing.md),
                    _buildRanking(context, vm),
                    const SizedBox(height: AppSpacing.md),
                    if (vm.myTeam != null) _buildMyTeam(vm),
                    const SizedBox(height: AppSpacing.lg),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(HomeViewModel vm) {
    final user = ProviderScope.containerOf(context)
        .read(authViewModelProvider)
        .currentUser;
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
            child: Text(name.substring(0, 1).toUpperCase(),
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
          _statCard(PhosphorIcons.trophy(), '${vm.myRank}', 'Lugar'),
          const SizedBox(width: AppSpacing.sm),
          _statCard(PhosphorIcons.users(), '${vm.playerCount}', 'Jogadores'),
          const SizedBox(width: AppSpacing.sm),
          _statCard(PhosphorIcons.lightning(), '${vm.winStreak}', 'Vitorias'),
        ]),
      ]),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
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
                  color: AppColors.textOnPrimary.withOpacity(0.6),
                  fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildNextMatch(Match match) {
    final teamA = match.teamASnapshot?.name ?? 'Time A';
    final teamB = match.teamBSnapshot?.name ?? 'Time B';
    final initialsA = teamA.substring(0, 2).toUpperCase();
    final initialsB = teamB.substring(0, 2).toUpperCase();
    final field = match.fieldSnapshot?.name ?? 'Local a definir';
    final date =
        '${match.scheduledDate.day.toString().padLeft(2, '0')}/${match.scheduledDate.month.toString().padLeft(2, '0')}/${match.scheduledDate.year}';

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
          onPressed: () => context.push(AppRoutes.matchDetail),
        ),
      ]),
    );
  }

  Widget _buildPendingRequest(Match match) {
    final teamA = match.teamASnapshot?.name ?? 'Time';
    final initialsA = teamA.substring(0, 2).toUpperCase();
    final field = match.fieldSnapshot?.name ?? 'Local a definir';
    final date =
        '${match.scheduledDate.day.toString().padLeft(2, '0')}/${match.scheduledDate.month.toString().padLeft(2, '0')}/${match.scheduledDate.year}';

    return AppCard(
      border: const Border(
          left: BorderSide(color: AppColors.warningIcon, width: 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppTeamAvatar(
              initials: initialsA, color: AppColors.avatarRed, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(teamA,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text('quer jogar contra seu time',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text('$date as ${match.scheduledTimeStart}  $field',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textDisabled)),
            ]),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          Expanded(
            child: AppButton.primary(
              label: 'Aceitar',
              icon: PhosphorIcons.check(),
              height: AppSizes.buttonHeightSmall,
              onPressed: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: AppButton.danger(
              label: 'Recusar',
              icon: PhosphorIcons.x(),
              height: AppSizes.buttonHeightSmall,
              onPressed: () {},
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildQuickActions() {
    return Row(children: [
      Expanded(
        child: AppCard(
          onTap: () => context.push(AppRoutes.search),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
    ]);
  }

  Widget _buildRanking(BuildContext context, HomeViewModel vm) {
    final rankings = ProviderScope.containerOf(context)
        .read(rankingViewModelProvider)
        .teamRankings
        .take(3)
        .toList();
    final colors = [
      AppColors.avatarBlue,
      AppColors.avatarRed,
      AppColors.avatarGreen,
    ];

    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Ranking dos times', style: AppTextStyles.titleSmall),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push(AppRoutes.ranking),
            child: Text('Ver todos',
                style: AppTextStyles.link.copyWith(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        ...rankings.asMap().entries.map((e) {
          final team = e.value;
          final initials = team.name.substring(0, 2).toUpperCase();
          final color = colors[e.key % colors.length];
          return Column(children: [
            if (e.key > 0) const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(children: [
                SizedBox(
                  width: 24,
                  child: Text('${team.rank}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: team.rank == 1
                              ? AppColors.warningIcon
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppTeamAvatar(
                    initials: initials, color: color, size: 32, fontSize: 12),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(team.name,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text('${team.matchesPlayed} jogos',
                            style: AppTextStyles.bodySmall),
                      ]),
                ),
                Text('${team.points} pts',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary, fontWeight: FontWeight.w700)),
              ]),
            ),
          ]);
        }),
      ]),
    );
  }

  Widget _buildMyTeam(HomeViewModel vm) {
    final team = vm.myTeam!;
    final initials = team.name.substring(0, 2).toUpperCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryHorizontal,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(children: [
        Row(children: [
          AppTeamAvatar(
              initials: initials, color: AppColors.primaryLight, size: 40),
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
                      color: AppColors.textOnPrimary.withOpacity(0.7),
                      fontSize: 12)),
            ]),
          ),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.teamManage),
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
          _teamStat('Jogadores', '${vm.playerCount}'),
          _teamStat('Serie', '${vm.winStreak}V'),
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
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Text(label,
              style: TextStyle(
                  color: AppColors.textOnPrimary.withOpacity(0.6),
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
