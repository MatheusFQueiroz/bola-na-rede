import 'package:flutter/material.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/app_main_nav_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildStatsGrid(),
            const SizedBox(height: AppSpacing.md),
            _buildMyTeams(context),
            const SizedBox(height: AppSpacing.md),
            _buildRecentMatches(),
            const SizedBox(height: AppSpacing.md),
            _buildAchievements(),
            const SizedBox(height: AppSpacing.md),
            _buildSettings(context),
            const SizedBox(height: AppSpacing.lg),
          ])),
        ),
      ]),
      bottomNavigationBar: const AppMainNavBar(currentIndex: 4),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(children: [
              const Spacer(),
              IconButton(
                icon: Icon(PhosphorIcons.gear(), color: AppColors.textOnPrimary),
                onPressed: () {},
              ),
            ]),
          ),
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.textOnPrimary, width: 3),
            ),
            alignment: Alignment.center,
            child: const Text('CS',
                style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w700, fontSize: 28)),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text('Carlos Souza',
              style: TextStyle(color: AppColors.textOnPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
          Text('Atacante  Sao Paulo, SP',
              style: TextStyle(color: AppColors.textOnPrimary.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Text('Capitao', style: TextStyle(color: AppColors.textOnPrimary, fontSize: 11)),
          ),
          const SizedBox(height: AppSpacing.xl),
        ]),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = [
      (PhosphorIcons.calendar(), 'Partidas', '42'),
      (PhosphorIcons.soccerBall(), 'Gols', '28'),
      (PhosphorIcons.trophy(), 'Vitorias', '28'),
      (PhosphorIcons.chartBar(), '% Vitorias', '67%'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: AppSpacing.md,
      mainAxisSpacing: AppSpacing.md,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.8,
      children: stats.map((s) => AppCard(
        child: Row(children: [
          Icon(s.$1, color: AppColors.primary, size: AppSizes.iconLg),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.$3, style: AppTextStyles.statNumber),
            Text(s.$2, style: AppTextStyles.statLabel),
          ]),
        ]),
      )).toList(),
    );
  }

  Widget _buildMyTeams(BuildContext context) {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Meus Times (2/3)', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.createTeam),
            child: const Text('Criar time'),
          ),
        ]),
        const Divider(),
        _teamRow('FU', AppColors.avatarGreen, 'Furacao FC', 'Capitao', 'Sao Paulo', context),
        const Divider(),
        _teamRow('LS', AppColors.avatarBlue, 'Los Sharkis', 'Membro', 'Sao Paulo', context),
      ]),
    );
  }

  Widget _teamRow(String initials, Color color, String name, String role, String city, BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: AppTeamAvatar(initials: initials, color: color, size: 40, fontSize: 13),
      title: Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(city, style: AppTextStyles.bodySmall),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (role == 'Capitao')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.xs),
            ),
            child: const Text('Capitao', style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
      ]),
      onTap: () => Navigator.pushNamed(context, AppRoutes.teamManage),
    );
  }

  Widget _buildRecentMatches() {
    final matches = [
      ('FU 3 x 1 UN', AppBadgeType.confirmed, '15/03  Soccer Place'),
      ('FU 2 x 2 D2', AppBadgeType.waiting, '10/03  Arena Xaxim'),
      ('FU 0 x 1 RS', AppBadgeType.closed, '05/03  Campo do Ze'),
    ];
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Ultimas partidas', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Ver todas')),
        ]),
        ...matches.map((m) => Column(children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.$1, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(m.$3, style: AppTextStyles.bodySmall),
              ])),
              AppBadge(type: m.$2),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      (PhosphorIcons.trophy(PhosphorIconsStyle.fill), 'Artilheiro', false),
      (PhosphorIcons.lightning(), 'Invicto', false),
      (PhosphorIcons.star(PhosphorIconsStyle.fill), 'MVP', false),
      (PhosphorIcons.medal(), 'Veterano', true),
    ];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Conquistas', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Ver todas')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: achievements.map((a) => Expanded(
          child: Opacity(
            opacity: a.$3 ? 0.4 : 1.0,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Column(children: [
                Icon(a.$1, color: a.$3 ? AppColors.textDisabled : AppColors.warningIcon, size: 22),
                const SizedBox(height: AppSpacing.xs),
                Text(a.$2, style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
              ]),
            ),
          ),
        )).toList()),
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
        _settingRow(PhosphorIcons.signOut(), 'Sair', true,
            () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.splash, (_) => false)),
      ]),
    );
  }

  Widget _settingRow(IconData icon, String label, bool isDanger, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: isDanger ? AppColors.error : AppColors.textSecondary),
      title: Text(label,
          style: TextStyle(
            color: isDanger ? AppColors.error : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          )),
      trailing: isDanger ? null : const Icon(Icons.chevron_right, color: AppColors.textDisabled),
      onTap: onTap,
    );
  }
}
