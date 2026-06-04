import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm = ref.watch(matchViewModelProvider);
    final match = vm.selectedMatch;

    final teamA = match?.teamASnapshot?.name ?? 'Furacao FC';
    final teamB = match?.teamBSnapshot?.name ?? 'Uniao Vila';
    final initialsA = teamA.substring(0, 2).toUpperCase();
    final initialsB = teamB.substring(0, 2).toUpperCase();
    final fieldName = match?.fieldSnapshot?.name ?? 'Arena Society Xaxim';
    final fieldAddr =
        match?.fieldSnapshot?.address ?? 'Rua das Araucarias, 450 — Xaxim';
    final timeRange = match != null
        ? '${match.scheduledTimeStart} – ${match.scheduledTimeEnd}'
        : '18:00 – 19:00';
    final date = match != null
        ? '${match.scheduledDate.day.toString().padLeft(2, '0')}/${match.scheduledDate.month.toString().padLeft(2, '0')}/${match.scheduledDate.year}'
        : 'Sab, 15/03/2025';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
        title: 'Detalhes da Partida',
        showBackButton: true,
        actions: [const AppBadge(type: AppBadgeType.confirmed)],
      ),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(children: [
            _buildVsCard(
                initialsA, teamA, initialsB, teamB, date, timeRange, fieldName),
            const SizedBox(height: AppSpacing.md),
            _buildPlayersCard(),
            const SizedBox(height: AppSpacing.md),
            _buildLocationCard(fieldName, fieldAddr),
            const SizedBox(height: AppSpacing.md),
            _buildRulesCard(),
            const SizedBox(height: 100),
          ]),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildFooter(context),
        ),
      ]),
    );
  }

  Widget _buildVsCard(String initialsA, String teamA, String initialsB,
      String teamB, String date, String timeRange, String fieldName) {
    return AppCard(
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Column(children: [
            AppTeamAvatar(
                initials: initialsA, color: AppColors.avatarGreen, size: 56),
            const SizedBox(height: AppSpacing.sm),
            Text(teamA, style: AppTextStyles.titleSmall),
          ]),
          Column(children: [
            Text('VS',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.textSecondary)),
            Text('Amistoso',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textDisabled)),
          ]),
          Column(children: [
            AppTeamAvatar(
                initials: initialsB, color: AppColors.avatarBlue, size: 56),
            const SizedBox(height: AppSpacing.sm),
            Text(teamB, style: AppTextStyles.titleSmall),
          ]),
        ]),
        const Divider(height: AppSpacing.xl),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
          Text(' $date',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.lg),
          Icon(PhosphorIcons.clock(), size: 14, color: AppColors.primary),
          Text(' $timeRange',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
          Text(' $fieldName',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildPlayersCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Jogadores confirmados', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _teamSection('Furacao FC', 4, 8, [
          ('CA', AppColors.avatarGreen, 'Carlos'),
          ('JO', AppColors.avatarTeal, 'Joao'),
          ('PE', AppColors.avatarBlue, 'Pedro'),
          ('LU', AppColors.avatarOrange, 'Lucas')
        ]),
        const Divider(height: AppSpacing.xl),
        _teamSection('Uniao Vila', 2, 7, [
          ('AN', AppColors.avatarBlue, 'Andre'),
          ('MA', AppColors.avatarPurple, 'Marcos')
        ]),
        Text('5 vagas abertas',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textDisabled, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _teamSection(String team, int confirmed, int total,
      List<(String, Color, String)> players) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(team,
            style:
                AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$confirmed/$total',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
      ]),
      const SizedBox(height: AppSpacing.sm),
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: LinearProgressIndicator(value: confirmed / total, minHeight: 6),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: players
            .map((p) => Row(mainAxisSize: MainAxisSize.min, children: [
                  AppTeamAvatar(
                      initials: p.$1, color: p.$2, size: 32, fontSize: 11),
                  const SizedBox(width: 4),
                  Text(p.$3, style: AppTextStyles.bodySmall),
                ]))
            .toList(),
      ),
    ]);
  }

  Widget _buildLocationCard(String name, String address) {
    return AppCard(
      onTap: () {},
      child: Row(children: [
        Icon(PhosphorIcons.mapPin(), size: 24, color: AppColors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.titleSmall),
            Text(address,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ]),
        ),
        Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
      ]),
    );
  }

  Widget _buildRulesCard() {
    return AppCard(
      child: Column(children: [
        _ruleRow(PhosphorIcons.soccerBall(), 'Modalidade', 'Society'),
        const Divider(),
        _ruleRow(PhosphorIcons.timer(), 'Duracao', '60 min'),
        const Divider(),
        _ruleRow(PhosphorIcons.user(), 'Arbitro', 'A combinar'),
        const Divider(),
        _ruleRow(PhosphorIcons.soccerBall(), 'Bola', 'Fornecida'),
      ]),
    );
  }

  Widget _ruleRow(IconData icon, String label, String value) {
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
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration:
          BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.modal),
      child: Row(children: [
        Expanded(
          child: AppButton.danger(
            label: 'Cancelar',
            height: AppSizes.buttonHeightSmall,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 2,
          child: AppButton.primary(
            label: 'Registrar Resultado',
            height: AppSizes.buttonHeightSmall,
            onPressed: () =>
                context.push(AppRoutes.registerResult),
          ),
        ),
      ]),
    );
  }
}
