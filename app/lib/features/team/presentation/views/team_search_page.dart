import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class TeamSearchPage extends ConsumerStatefulWidget {
  const TeamSearchPage({super.key});

  @override
  ConsumerState<TeamSearchPage> createState() => _TeamSearchPageState();
}

class _TeamSearchPageState extends ConsumerState<TeamSearchPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamViewModelProvider.notifier).loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(context),
        Expanded(child: _buildBody()),
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
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Row(children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft(),
                    color: AppColors.textOnPrimary),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Text('Selecionar Adversário',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 48),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar time...',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass(),
                      color: AppColors.textSecondary),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildBody() {
    final vm = ref.watch(teamViewModelProvider);

    if (vm.status == TeamStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.status == TeamStatus.error) {
      return Center(
        child: Text(vm.error ?? 'Erro',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary)),
      );
    }

    final teams = vm.teams
        .where((t) => t.id != 'team-001')
        .where((t) =>
            _query.isEmpty ||
            t.name.toLowerCase().contains(_query) ||
            t.city.toLowerCase().contains(_query))
        .toList();

    if (teams.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(PhosphorIcons.users(), size: 48, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          const Text('Nenhum time encontrado',
              style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Tente outro nome',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
        ]),
      );
    }

    final colors = [
      AppColors.avatarGreen,
      AppColors.avatarBlue,
      AppColors.avatarRed,
      AppColors.avatarOrange,
      AppColors.avatarPurple,
      AppColors.avatarTeal,
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: teams.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (_, i) {
        final team = teams[i];
        final initials = team.name.substring(0, 2).toUpperCase();
        final color = colors[i % colors.length];

        return AppCard(
          onTap: () => context.pop(team),
          child: Row(children: [
            AppTeamAvatar(
                initials: initials, color: color, size: 48, fontSize: 15),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: AppTextStyles.titleSmall),
                    Text(team.city,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ]),
            ),
            Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
          ]),
        );
      },
    );
  }
}
