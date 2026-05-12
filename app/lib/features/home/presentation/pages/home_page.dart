import 'package:flutter/material.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../shared/widgets/app_main_nav_bar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildNextMatch(),
                const SizedBox(height: AppSpacing.md),
                _buildPendingRequest(),
                const SizedBox(height: AppSpacing.md),
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.md),
                _buildRanking(),
                const SizedBox(height: AppSpacing.md),
                _buildMyTeam(),
                const SizedBox(height: AppSpacing.lg),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppMainNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.lg,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.xl,
      ),
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: Column(
        children: [
          Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: AppColors.primaryLight, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Text('C',
                  style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Bem-vindo de volta,',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textOnPrimary)),
              const Text('Carlos',
                  style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ]),
            const Spacer(),
            Icon(PhosphorIcons.mapPin(),
                color: AppColors.textOnPrimary, size: 14),
            Text(' Sao Paulo',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textOnPrimary)),
          ]),
          const SizedBox(height: AppSpacing.lg),
          // Stats
          Row(children: [
            _statCard(PhosphorIcons.trophy(), '3', 'Lugar'),
            const SizedBox(width: AppSpacing.sm),
            _statCard(PhosphorIcons.users(), '6', 'Jogadores'),
            const SizedBox(width: AppSpacing.sm),
            _statCard(PhosphorIcons.lightning(), '8', 'Vitorias'),
          ]),
        ],
      ),
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

  Widget _buildNextMatch() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Proxima Partida...',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const Spacer(),
          const AppBadge(type: AppBadgeType.confirmed),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Column(children: [
            const AppTeamAvatar(
                initials: 'FU', color: AppColors.avatarGreen, size: 48),
            const SizedBox(height: AppSpacing.xs),
            const Text('Furacao FC', style: AppTextStyles.labelMedium),
          ]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('VS',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          Column(children: [
            const AppTeamAvatar(
                initials: 'UN', color: AppColors.avatarBlue, size: 48),
            const SizedBox(height: AppSpacing.xs),
            const Text('Uniao Vila', style: AppTextStyles.labelMedium),
          ]),
        ]),
        const SizedBox(height: AppSpacing.md),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.calendar(),
              size: 14, color: AppColors.primary),
          Text(' 15/03/2025  ',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          Icon(PhosphorIcons.clock(),
              size: 14, color: AppColors.primary),
          Text(' 18:00',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.mapPin(),
              size: 14, color: AppColors.primary),
          Text(' Soccer Place',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.md),
        const Divider(),
        const SizedBox(height: AppSpacing.md),
        Text('Jogadores confirmados',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        _progressBar('Furacao FC', 4, 8),
        const SizedBox(height: AppSpacing.sm),
        _progressBar('Uniao Vila', 2, 7),
        const SizedBox(height: AppSpacing.md),
        AppButton.outline(
          label: 'Ver detalhes',
          height: AppSizes.buttonHeightSmall,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.matchDetail),
        ),
      ]),
    );
  }

  Widget _progressBar(String team, int confirmed, int total) {
    return Row(children: [
      SizedBox(
        width: 80,
        child: Text(team,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis),
      ),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Stack(children: [
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          FractionallySizedBox(
            widthFactor: confirmed / total,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              alignment: Alignment.center,
              child: Text('$confirmed/$total',
                  style: const TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildPendingRequest() {
    return AppCard(
      border: const Border(
          left: BorderSide(color: AppColors.warningIcon, width: 4)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const AppTeamAvatar(
              initials: 'D2', color: AppColors.avatarRed, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dragoes da ZL',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary)),
              Text('quer jogar contra seu time',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text('25/03/2025 as 19:00  Arena Sports',
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
          onTap: () => Navigator.pushNamed(context, AppRoutes.search),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(PhosphorIcons.magnifyingGlass(), color: AppColors.primary, size: AppSizes.iconLg),
              const SizedBox(height: AppSpacing.sm),
              const Text('Buscar partida', style: AppTextStyles.titleSmall),
              Text('Encontre adversarios',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.md),
      Expanded(
        child: AppCard(
          onTap: () => Navigator.pushNamed(context, AppRoutes.fieldCatalog),
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
            ],
          ),
        ),
      ),
    ]);
  }

  Widget _buildRanking() {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Ranking dos times', style: AppTextStyles.titleSmall),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.ranking),
            child: Text('Ver todos',
                style: AppTextStyles.link.copyWith(fontSize: 13)),
          ),
        ]),
        const SizedBox(height: AppSpacing.md),
        _rankingItem(1, 'UN', AppColors.avatarBlue, 'Uniao Vila', '46 jogos', '40 pts'),
        const Divider(),
        _rankingItem(2, 'D2', AppColors.avatarRed, 'Dragoes da ZL', '36 jogos', '30 pts'),
        const Divider(),
        _rankingItem(3, 'FU', AppColors.avatarGreen, 'Furacao FC', '42 jogos', '20 pts'),
      ]),
    );
  }

  Widget _rankingItem(int pos, String initials, Color color,
      String name, String games, String pts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        SizedBox(
          width: 24,
          child: Text('$pos',
              style: AppTextStyles.bodySmall.copyWith(
                  color: pos == 1 ? AppColors.warningIcon : AppColors.textSecondary,
                  fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppTeamAvatar(initials: initials, color: color, size: 32, fontSize: 12),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: AppTextStyles.bodyMedium
                    .copyWith(fontWeight: FontWeight.w700)),
            Text(games, style: AppTextStyles.bodySmall),
          ]),
        ),
        Text(pts,
            style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildMyTeam() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryHorizontal,
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(children: [
        Row(children: [
          const AppTeamAvatar(
              initials: 'FU', color: AppColors.primaryLight, size: 40),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Furacao FC',
                  style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              Text('Sao Paulo, SP',
                  style: TextStyle(
                      color: AppColors.textOnPrimary.withOpacity(0.7),
                      fontSize: 12)),
            ]),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.teamManage),
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
          _teamStat('Jogadores', '6'),
          _teamStat('Serie', '3V'),
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
