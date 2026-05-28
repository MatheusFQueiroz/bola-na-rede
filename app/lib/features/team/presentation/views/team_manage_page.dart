import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class TeamManagePage extends StatelessWidget {
  const TeamManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(delegate: SliverChildListDelegate([
            _buildMembersCard(),
            const SizedBox(height: AppSpacing.md),
            _buildPendingCard(),
            const SizedBox(height: AppSpacing.md),
            _buildRecentMatchesCard(),
            const SizedBox(height: AppSpacing.md),
            _buildDangerCard(),
            const SizedBox(height: AppSpacing.lg),
          ])),
        ),
      ]),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              const Expanded(
                child: Text('Furacao FC', textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textOnPrimary, fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              IconButton(
                icon: Icon(PhosphorIcons.pencil(), color: AppColors.textOnPrimary),
                onPressed: () {},
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          const AppTeamAvatar(initials: 'FU', color: AppColors.primaryLight, size: 72, fontSize: 24),
          const SizedBox(height: AppSpacing.sm),
          const Text('Furacao FC',
              style: TextStyle(color: AppColors.textOnPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          Text('Sao Paulo, SP',
              style: TextStyle(color: AppColors.textOnPrimary.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(
              color: AppColors.textOnPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
          Text(label, style: TextStyle(
              color: AppColors.textOnPrimary.withOpacity(0.6), fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildMembersCard() {
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
          TextButton(onPressed: () {}, child: const Text('Convidar')),
        ]),
        ...members.map((m) => Column(children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(children: [
              AppTeamAvatar(
                initials: m.$1.substring(0, 2).toUpperCase(),
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
                IconButton(icon: Icon(PhosphorIcons.dotsThreeVertical(), color: AppColors.textDisabled), onPressed: () {}),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildPendingCard() {
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
              onPressed: () {},
              child: const Text('Cancelar', style: TextStyle(color: AppColors.error, fontSize: 12)),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildRecentMatchesCard() {
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
          TextButton(onPressed: () {}, child: const Text('Ver todas')),
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
