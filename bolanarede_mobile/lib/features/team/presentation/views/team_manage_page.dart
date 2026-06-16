import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/string_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class TeamManagePage extends ConsumerWidget {
  const TeamManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = GoRouterState.of(context).pathParameters['id']!;
    return ref.watch(teamDetailProvider(id)).when(
          data: (team) => _buildPage(context, team),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            appBar: AppGradientAppBar(title: 'Time', showBackButton: true),
            body: const Center(
                child: Text('Não foi possível carregar o time.')),
          ),
        );
  }

  Widget _buildPage(BuildContext context, Team team) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, team)),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildMembersCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildPendingCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildRecentMatchesCard(context),
            const SizedBox(height: AppSpacing.md),
            _buildDangerCard(),
            const SizedBox(height: AppSpacing.lg),
          ])),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context, Team team) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(), color: AppColors.textOnPrimary),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(team.name, textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.pencil(), color: AppColors.textOnPrimary),
                onPressed: () => showComingSoon(context),
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTeamAvatar(initials: initials(team.name), color: AppColors.primaryLight, size: 72, fontSize: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(team.name,
              style: const TextStyle(color: AppColors.textOnPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          Text(team.city,
              style: TextStyle(color: AppColors.textOnPrimary.withValues(alpha: 0.7), fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Text('Capitao',
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 11)),
          ),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(children: [
              _miniStat('Jogadores', '6'),
              _miniStat('Jogos', '42'),
              _miniStat('Vitorias', '28'),
            ]),
          ),
          const SizedBox(height: AppSpacing.xl),
        ]),
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(
              color: AppColors.textOnPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: TextStyle(
              color: AppColors.textOnPrimary.withValues(alpha: 0.6), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildMembersCard(BuildContext context) {
    final members = [
      ('Carlos Souza', 'Atacante', true),
      ('Joao Silva', 'Goleiro', false),
      ('Pedro Alves', 'Zagueiro', false),
      ('Lucas Costa', 'Meia', false),
      ('Rafael Lima', 'Lateral', false),
      ('Bruno Martins', 'Atacante', false),
    ];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Membros (6/8)', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () => showComingSoon(context), child: const Text('Convidar')),
        ]),
        ...members.map((m) => Column(children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(children: [
              AppTeamAvatar(
                initials: initials(m.$1),
                color: AppColors.avatarGreen,
                size: 40, fontSize: 13,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.$1, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                Text(m.$2, style: AppTextStyles.bodySmall),
              ])),
              if (m.$3)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Text('Capitao',
                      style: TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
                )
              else
                IconButton(icon: Icon(PhosphorIcons.dotsThreeVertical(), color: AppColors.textDisabled), onPressed: () => showComingSoon(context)),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildPendingCard(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Convites enviados (1)', style: AppTextStyles.titleSmall),
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle),
              child: Icon(PhosphorIcons.user(), color: AppColors.textDisabled),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Felipe Rocha', style: AppTextStyles.labelMedium),
              Text('Enviado ha 2 dias', style: AppTextStyles.bodySmall),
            ])),
            TextButton(
              onPressed: () => showComingSoon(context),
              child: const Text('Cancelar', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRecentMatchesCard(BuildContext context) {
    final matches = [
      ('FU 3 x 1 UN', AppBadgeType.confirmed, '10/03'),
      ('FU 2 x 2 D2', AppBadgeType.waiting, '05/03'),
      ('FU 0 x 1 RS', AppBadgeType.closed, '01/03'),
    ];
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Partidas recentes', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () => showComingSoon(context), child: const Text('Ver todas')),
        ]),
        ...matches.map((m) => Column(children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(children: [
              Expanded(child: Text(m.$1, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700))),
              AppBadge(type: m.$2),
              const SizedBox(width: AppSpacing.sm),
              Text(m.$3, style: AppTextStyles.bodySmall),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildDangerCard() {
    return AppCard(
      border: Border.all(color: AppColors.errorSurface),
      child: Column(children: [
        ListTile(
          leading: Icon(PhosphorIcons.arrowsLeftRight(), color: AppColors.error),
          title: const Text('Transferir capitania',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
          trailing: Icon(PhosphorIcons.caretRight(), color: AppColors.error),
          onTap: () {},
          contentPadding: EdgeInsets.zero,
        ),
        const Divider(),
        ListTile(
          leading: Icon(PhosphorIcons.trash(), color: AppColors.error),
          title: const Text('Desfazer time',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w500)),
          trailing: Icon(PhosphorIcons.caretRight(), color: AppColors.error),
          onTap: () {},
          contentPadding: EdgeInsets.zero,
        ),
      ]),
    );
  }
}
