import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_provider.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class OpenChallengesPage extends ConsumerWidget {
  const OpenChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
        title: 'Desafios Abertos',
        showBackButton: true,
        actions: [
          IconButton(
            icon: Icon(PhosphorIcons.plus(), color: AppColors.textOnPrimary),
            onPressed: () => context.push(AppRoutes.createMatch),
          ),
        ],
      ),
      body: ref.watch(openChallengesProvider).when(
            data: (requests) {
              final pending = requests
                  .where((r) => r.status == MatchRequestStatus.pending)
                  .toList();
              return pending.isEmpty
                  ? _buildEmpty(context)
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(openChallengesProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: pending.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (_, i) =>
                            _ChallengeCard(request: pending[i]),
                      ),
                    );
            },
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: 4,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, __) => const AppShimmerCard(),
            ),
            error: (_, __) => Center(
              child: Text(
                'Não foi possível carregar os desafios.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(PhosphorIcons.handFist(),
              size: 64, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Nenhum desafio aberto no momento.',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Crie um desafio para encontrar adversários.',
            style:
                AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButtonSmall(
            label: 'Criar desafio',
            onPressed: () => context.push(AppRoutes.createMatch),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends ConsumerStatefulWidget {
  const _ChallengeCard({required this.request});

  final MatchRequest request;

  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  bool _accepting = false;

  String _timeAgo(DateTime createdAt) {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }

  String _avatarInitials(String teamId) {
    if (teamId.length >= 2) return teamId.substring(0, 2).toUpperCase();
    return teamId.toUpperCase();
  }

  Future<void> _accept() async {
    setState(() => _accepting = true);
    try {
      await ref.read(matchRepositoryProvider).acceptMatch(widget.request.id);
      ref.invalidate(openChallengesProvider);
      ref.invalidate(matchListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Desafio aceito com sucesso!')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível aceitar o desafio.')),
      );
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final initials = _avatarInitials(request.requestingTeamId);
    final timeAgo = _timeAgo(request.createdAt);

    return AppCard(
      child: Row(
        children: [
          AppTeamAvatar(
            initials: initials,
            color: AppColors.avatarBlue,
            size: AppSizes.avatarMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jogador em busca de partida',
                  style: AppTextStyles.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${request.preferredCity} · $timeAgo',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppButtonSmall(
            label: _accepting ? '...' : 'Aceitar',
            onPressed: _accepting ? null : _accept,
          ),
        ],
      ),
    );
  }
}
