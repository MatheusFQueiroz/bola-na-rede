import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/peladas/data/datasources/open_game_datasource_provider.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class PeladaDetailPage extends ConsumerWidget {
  const PeladaDetailPage({required this.id, super.key});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(openGameDetailProvider(id));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: gameAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Não foi possível carregar a pelada.',
            style:
                AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (game) => _buildContent(context, ref, game),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, OpenGame game) {
    final user = ref.watch(authViewModelProvider).value;
    final isOrganizer = user?.userId == game.organizerUserId;
    final date = game.scheduledAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final endTime = date.add(Duration(minutes: game.durationMinutes));
    final endTimeStr =
        '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    final location =
        game.fieldNameSnapshot ?? game.fieldAddressSnapshot ?? 'Local a definir';
    final sportLabel = _sportLabel(game.sport);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.primaryVertical),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(PhosphorIcons.arrowLeft(),
                              color: AppColors.textOnPrimary),
                          onPressed: () => context.pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Detalhe da Pelada',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    child: Column(
                      children: [
                        Text(
                          game.title,
                          style: const TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          sportLabel,
                          style: TextStyle(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              AppCard(
                child: Column(
                  children: [
                    _infoRow(
                      PhosphorIcons.calendar(),
                      'Data',
                      '$dateStr às $timeStr – $endTimeStr',
                    ),
                    const Divider(),
                    _infoRow(PhosphorIcons.mapPin(), 'Local', location),
                    const Divider(),
                    _infoRow(
                      PhosphorIcons.users(),
                      'Jogadores',
                      '${game.participantCount}/${game.maxPlayers} (mín. ${game.minPlayers})',
                    ),
                    if (game.pricePerPlayer != null) ...[
                      const Divider(),
                      _infoRow(
                        PhosphorIcons.currencyDollar(),
                        'Valor',
                        'R\$ ${game.pricePerPlayer!.toStringAsFixed(2)} / jogador',
                      ),
                    ],
                  ],
                ),
              ),
              if (game.description != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Descrição', style: AppTextStyles.titleSmall),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        game.description!,
                        style: AppTextStyles.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              if (game.isOpen && !game.isFull && !isOrganizer)
                AppButton.primary(
                  label: 'Entrar na pelada',
                  icon: PhosphorIcons.signIn(),
                  onPressed: () => _join(context, ref),
                ),
              if (isOrganizer && game.isOpen)
                AppButton.danger(
                  label: 'Cancelar pelada',
                  icon: PhosphorIcons.x(),
                  onPressed: () => _cancel(context, ref),
                ),
              if (!isOrganizer && game.isOpen)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: AppButton.outline(
                    label: 'Sair da pelada',
                    onPressed: () => _leave(context, ref),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              Text(value,
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _join(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(openGameRepositoryProvider).joinOpenGame(id);
      ref.invalidate(openGameDetailProvider(id));
      ref.invalidate(openGameListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você entrou na pelada!')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível entrar na pelada.')),
      );
    }
  }

  Future<void> _leave(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(openGameRepositoryProvider).leaveOpenGame(id);
      ref.invalidate(openGameDetailProvider(id));
      ref.invalidate(openGameListProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você saiu da pelada.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível sair da pelada.')),
      );
    }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar pelada'),
        content: const Text('Tem certeza que deseja cancelar esta pelada?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Não'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sim, cancelar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(openGameRepositoryProvider).cancelOpenGame(id);
      ref.invalidate(openGameListProvider);
      if (!context.mounted) return;
      context.pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Não foi possível cancelar a pelada.')),
      );
    }
  }

  String _sportLabel(String sport) => switch (sport) {
        'futsal' => 'Futsal',
        'society' => 'Society',
        'campo' => 'Campo',
        _ => sport,
      };
}
