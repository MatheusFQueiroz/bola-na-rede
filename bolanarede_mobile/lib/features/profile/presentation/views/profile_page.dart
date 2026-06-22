import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ref.watch(profileProvider).when(
            data: (data) => _buildContent(context, ref, data),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Não foi possível carregar o perfil.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
    );
  }

  Widget _buildContent(
      BuildContext context, WidgetRef ref, ProfileData data) {
    final profile = data.profile;
    final avatarInitials = initials(profile.displayName);
    final name = profile.displayName;
    final city = profile.city ?? 'Curitiba';
    final position = _positionLabel(profile.position);

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(
          child: _buildHeader(context, ref, avatarInitials, name, city, position)),
      SliverPadding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        sliver: SliverList(
            delegate: SliverChildListDelegate([
          _buildStatsGrid(data),
          const SizedBox(height: AppSpacing.md),
          _buildMyTeams(context, ref),
          const SizedBox(height: AppSpacing.md),
          _buildRecentMatches(context, data),
          const SizedBox(height: AppSpacing.md),
          _buildSettings(context, ref),
          const SizedBox(height: AppSpacing.lg),
        ])),
      ),
    ]);
  }

  String _positionLabel(PlayerPosition? position) {
    switch (position) {
      case PlayerPosition.goalkeeper:
        return 'Goleiro';
      case PlayerPosition.defender:
        return 'Zagueiro';
      case PlayerPosition.midfielder:
        return 'Meia';
      case PlayerPosition.forward:
        return 'Atacante';
      default:
        return 'Jogador';
    }
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, String avatarInitials,
      String name, String city, String position) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(children: [
              const Spacer(),
              IconButton(
                icon:
                    Icon(PhosphorIcons.gear(), color: AppColors.textOnPrimary),
                onPressed: () => showComingSoon(context),
              ),
            ]),
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textOnPrimary, width: 3),
            ),
            alignment: Alignment.center,
            child: Text(avatarInitials,
                style: const TextStyle(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 28)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(name,
              style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 20)),
          Text('$position  $city',
              style: TextStyle(
                  color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Text('Capitao',
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 11)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ]),
      ),
    );
  }

  Widget _buildStatsGrid(ProfileData data) {
    final stats = [
      (PhosphorIcons.calendar(), 'Partidas', '${data.totalMatches}'),
      (PhosphorIcons.soccerBall(), 'Gols', '${data.totalGoals}'),
      (PhosphorIcons.trophy(), 'Vitorias', '${data.totalWins}'),
      (PhosphorIcons.chartBar(), '% Vitorias', data.winRate),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: stats
          .map((s) => AppCard(
                child: Row(children: [
                  Icon(s.$1, color: AppColors.primary, size: AppSizes.iconLg),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$3, style: AppTextStyles.statNumber),
                        Text(s.$2, style: AppTextStyles.statLabel),
                      ]),
                ]),
              ))
          .toList(),
    );
  }

  Widget _buildMyTeams(BuildContext context, WidgetRef ref) {
    final teamsAsync = ref.watch(teamListProvider);
    final myTeamAsync = ref.watch(myTeamProvider);

    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              Text(
                teamsAsync.whenOrNull(data: (ts) => 'Meus Times (${ts.length})')
                    ?? 'Meus Times',
                style: AppTextStyles.titleSmall,
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push(AppRoutes.createTeam),
                child: const Text('Criar time'),
              ),
            ],
          ),
          ...teamsAsync.when(
            loading: () => [
              const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
            error: (_, __) => [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Text(
                  'Não foi possível carregar os times.',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
            data: (teams) {
              final myTeam = myTeamAsync.value;
              if (myTeam == null) {
                return [
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Text(
                      'Você não faz parte de nenhum time.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        context.push(AppRoutes.teamSearchJoin),
                    child: const Text('Procurar Time'),
                  ),
                ];
              }
              return teams
                  .map((t) => _teamRowFromEntity(t, context))
                  .expand((w) => [const Divider(), w])
                  .toList();
            },
          ),
        ],
      ),
    );
  }

  Widget _teamRowFromEntity(Team team, BuildContext context) {
    final avatarColor = AppColors.avatarGreen;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppTeamAvatar(
        initials: initials(team.name),
        color: avatarColor,
        size: 40,
        fontSize: 13,
      ),
      title: Text(
        team.name,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(team.city, style: AppTextStyles.bodySmall),
      trailing: Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
      onTap: () => context.push(AppRoutes.teamManageOf(team.id)),
    );
  }

  Widget _buildRecentMatches(BuildContext context, ProfileData data) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Ultimas partidas', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () => context.push(AppRoutes.matchList), child: const Text('Ver todas')),
        ]),
        ...data.recentMatches.map((m) {
          final badgeType = m['result'] == 'win'
              ? AppBadgeType.confirmed
              : m['result'] == 'draw'
                  ? AppBadgeType.waiting
                  : AppBadgeType.closed;

          return Column(children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['title'] as String,
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w700)),
                        Text('${m['date']}  ${m['location']}',
                            style: AppTextStyles.bodySmall),
                      ]),
                ),
                AppBadge(type: badgeType),
              ]),
            ),
          ]);
        }),
      ]),
    );
  }

  Widget _buildSettings(BuildContext context, WidgetRef ref) {
    return AppCard(
      child: Column(children: [
        _settingRow(PhosphorIcons.user(), 'Editar perfil', false, () => context.push(AppRoutes.editProfile)),
        const Divider(),
        _settingRow(PhosphorIcons.bell(), 'Notificacoes', false, () => context.push(AppRoutes.notifications)),
        const Divider(),
        _settingRow(
          PhosphorIcons.signOut(),
          'Sair',
          true,
          () async {
            await ref.read(authViewModelProvider.notifier).logout();
            if (!context.mounted) return;
            context.go(AppRoutes.splash);
          },
        ),
      ]),
    );
  }

  Widget _settingRow(
      IconData icon, String label, bool isDanger, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon,
          color: isDanger ? AppColors.error : AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
            color: isDanger ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          )),
      trailing: isDanger
          ? null
          : Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
