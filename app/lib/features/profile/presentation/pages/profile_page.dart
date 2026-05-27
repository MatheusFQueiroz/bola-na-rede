import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:provider/provider.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';
import '../viewmodels/profile_viewmodel.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileViewModel>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProfileViewModel>(
        builder: (_, vm, __) {
          if (vm.state == ProfileViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (vm.state == ProfileViewState.error) {
            return Center(child: Text(vm.error ?? 'Erro'));
          }

          final profile = vm.profile;
          final initials =
              profile?.displayName.substring(0, 2).toUpperCase() ?? 'CS';
          final name = profile?.displayName ?? 'Carlos Souza';
          final city = profile?.city ?? 'Curitiba';
          final position = _positionLabel(profile?.position);

          return CustomScrollView(slivers: [
            SliverToBoxAdapter(
                child: _buildHeader(initials, name, city, position)),
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                  delegate: SliverChildListDelegate([
                _buildStatsGrid(vm),
                const SizedBox(height: AppSpacing.md),
                _buildMyTeams(context),
                const SizedBox(height: AppSpacing.md),
                _buildRecentMatches(vm),
                const SizedBox(height: AppSpacing.md),
                const SizedBox(height: AppSpacing.md),
                _buildSettings(context),
                const SizedBox(height: AppSpacing.lg),
              ])),
            ),
          ]);
        },
      ),
    );
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

  Widget _buildHeader(
      String initials, String name, String city, String position) {
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
                onPressed: () {},
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
            child: Text(initials,
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
                  color: AppColors.textOnPrimary.withOpacity(0.7),
                  fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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

  Widget _buildStatsGrid(ProfileViewModel vm) {
    final stats = [
      (PhosphorIcons.calendar(), 'Partidas', '${vm.totalMatches}'),
      (PhosphorIcons.soccerBall(), 'Gols', '${vm.totalGoals}'),
      (PhosphorIcons.trophy(), 'Vitorias', '${vm.totalWins}'),
      (PhosphorIcons.chartBar(), '% Vitorias', vm.winRate),
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

  Widget _buildMyTeams(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Meus Times (2/3)', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(
            onPressed: () => context.push(AppRoutes.createTeam),
            child: const Text('Criar time'),
          ),
        ]),
        const Divider(),
        _teamRow('FU', AppColors.avatarGreen, 'Furacao FC', 'Capitao',
            'Curitiba', context),
        const Divider(),
        _teamRow('LS', AppColors.avatarBlue, 'Los Sharkis', 'Membro',
            'Curitiba', context),
      ]),
    );
  }

  Widget _teamRow(String initials, Color color, String name, String role,
      String city, BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppTeamAvatar(
          initials: initials, color: color, size: 40, fontSize: 13),
      title: Text(name,
          style:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(city, style: AppTextStyles.bodySmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (role == 'Capitao')
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Text('Capitao',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
        Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
      ]),
      onTap: () => context.push(AppRoutes.teamManage),
    );
  }

  Widget _buildRecentMatches(ProfileViewModel vm) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Ultimas partidas', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Ver todas')),
        ]),
        ...vm.recentMatches.map((m) {
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

  Widget _buildSettings(BuildContext context) {
    return AppCard(
      child: Column(children: [
        _settingRow(PhosphorIcons.user(), 'Editar perfil', false, () {}),
        const Divider(),
        _settingRow(PhosphorIcons.bell(), 'Notificacoes', false, () {}),
        const Divider(),
        _settingRow(PhosphorIcons.shield(), 'Privacidade', false, () {}),
        const Divider(),
        _settingRow(
          PhosphorIcons.signOut(),
          'Sair',
          true,
          () async {
            await context.read<AuthViewModel>().logout();
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
          : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
