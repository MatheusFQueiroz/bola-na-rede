import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/team/data/repositories/team_repository_provider.dart';
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
          data: (team) => _buildPage(context, ref, team),
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

  Widget _buildPage(BuildContext context, WidgetRef ref, Team team) {
    final myUserId = ref.watch(authViewModelProvider).value?.userId ?? '';
    final isCaptain = team.createdBy == myUserId;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _buildHeader(context, ref, team, isCaptain)),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _MembersCard(teamId: team.id, isCaptain: isCaptain),
              const SizedBox(height: AppSpacing.md),
              if (isCaptain) _buildDangerCard(context, ref, team),
              if (!isCaptain) _buildLeaveCard(context, ref, team),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, Team team, bool isCaptain) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(),
                    color: AppColors.textOnPrimary),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: Text(team.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 48),
            ]),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTeamAvatar(
              initials: initials(team.name),
              color: AppColors.primaryLight,
              size: 72,
              fontSize: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(team.name,
              style: const TextStyle(
                  color: AppColors.textOnPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700)),
          if (isCaptain)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.xs),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Text('Capitão',
                  style: TextStyle(
                      color: AppColors.textOnPrimary, fontSize: 11)),
            ),
          const SizedBox(height: AppSpacing.xl),
        ]),
      ),
    );
  }

  Widget _buildDangerCard(BuildContext context, WidgetRef ref, Team team) {
    return AppCard(
      border: Border.all(color: AppColors.errorSurface),
      child: Column(children: [
        ListTile(
          leading: Icon(PhosphorIcons.trash(), color: AppColors.error),
          title: const Text('Desfazer time',
              style: TextStyle(
                  color: AppColors.error, fontWeight: FontWeight.w500)),
          trailing: Icon(PhosphorIcons.caretRight(), color: AppColors.error),
          onTap: () => showComingSoon(context),
          contentPadding: EdgeInsets.zero,
        ),
      ]),
    );
  }

  Widget _buildLeaveCard(BuildContext context, WidgetRef ref, Team team) {
    return AppCard(
      border: Border.all(color: AppColors.errorSurface),
      child: ListTile(
        leading: Icon(PhosphorIcons.signOut(), color: AppColors.error),
        title: const Text('Sair do time',
            style: TextStyle(
                color: AppColors.error, fontWeight: FontWeight.w500)),
        trailing: Icon(PhosphorIcons.caretRight(), color: AppColors.error),
        onTap: () => _confirmLeave(context, ref, team),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> _confirmLeave(
      BuildContext context, WidgetRef ref, Team team) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do time'),
        content:
            Text('Tem certeza que deseja sair de "${team.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(teamRepositoryProvider).leaveTeam(team.id);
      ref.invalidate(teamListProvider);
      if (!context.mounted) return;
      context.pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair do time.')),
      );
    }
  }
}

class _MembersCard extends ConsumerWidget {
  const _MembersCard({required this.teamId, required this.isCaptain});

  final String teamId;
  final bool isCaptain;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(teamMembersProvider(teamId)).when(
          data: (members) {
            final active = members.where((m) => m.isActive).toList();
            return AppCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text('Membros (${active.length})',
                          style: AppTextStyles.titleSmall),
                      const Spacer(),
                      if (isCaptain)
                        TextButton(
                          onPressed: () => showComingSoon(context),
                          child: const Text('Convidar'),
                        ),
                    ]),
                    ...active.map((m) => _memberRow(context, ref, m)),
                  ]),
            );
          },
          loading: () => const AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (_, __) => const AppCard(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text('Não foi possível carregar membros.'),
            ),
          ),
        );
  }

  Widget _memberRow(
      BuildContext context, WidgetRef ref, TeamMember member) {
    final name = member.displayName ?? member.userId.substring(0, 8);
    final isCaptainMember = member.role == TeamMemberRole.captain;

    return Column(children: [
      const Divider(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(children: [
          AppTeamAvatar(
            initials: initials(name),
            color: isCaptainMember ? AppColors.avatarGreen : AppColors.avatarBlue,
            size: 40,
            fontSize: 13,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(name,
                    style: AppTextStyles.bodyMedium
                        .copyWith(fontWeight: FontWeight.w600)),
                Text(
                    isCaptainMember ? 'Capitão' : 'Membro',
                    style: AppTextStyles.bodySmall),
              ])),
          if (isCaptainMember)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: const Text('Capitão',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
            )
          else if (isCaptain)
            IconButton(
              icon: Icon(PhosphorIcons.dotsThreeVertical(),
                  color: AppColors.textDisabled),
              onPressed: () => showComingSoon(context),
            ),
        ]),
      ),
    ]);
  }
}
