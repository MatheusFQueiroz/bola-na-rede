import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class PeladasListPage extends ConsumerStatefulWidget {
  const PeladasListPage({super.key});

  @override
  ConsumerState<PeladasListPage> createState() => _PeladasListPageState();
}

class _PeladasListPageState extends ConsumerState<PeladasListPage> {
  String? _sport;

  static const _sports = <String?>['Todos', 'futsal', 'society', 'campo'];

  String _sportLabel(String? sport) => switch (sport) {
        'futsal' => 'Futsal',
        'society' => 'Society',
        'campo' => 'Campo',
        _ => 'Todos',
      };

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(openGameListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
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
                            'Peladas',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textOnPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIcons.plus(),
                              color: AppColors.textOnPrimary),
                          onPressed: () =>
                              context.push(AppRoutes.createPelada),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      itemCount: _sports.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final sport = _sports[i];
                        return AppFilterChip(
                          label: _sportLabel(sport),
                          selected: _sport == sport,
                          onTap: () {
                            setState(() => _sport = sport);
                            ref
                                .read(openGameListProvider.notifier)
                                .filterBySport(sport);
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
          Expanded(
            child: gamesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Não foi possível carregar as peladas.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              data: (games) => games.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.soccerBall(),
                              size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Nenhuma pelada encontrada',
                            style: AppTextStyles.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButtonSmall(
                            label: 'Criar pelada',
                            filled: true,
                            onPressed: () =>
                                context.push(AppRoutes.createPelada),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: games.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (_, i) => _gameCard(games[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gameCard(OpenGame game) {
    final sportLabel = _sportLabel(game.sport);
    final date = game.scheduledAt;
    final dateStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    final location =
        game.fieldNameSnapshot ?? game.fieldAddressSnapshot ?? 'Local a definir';
    final spotsLeft = game.maxPlayers - game.participantCount;

    return AppCard(
      onTap: () => context.push(AppRoutes.peladaDetailOf(game.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: game.isOpen && !game.isFull
                      ? AppColors.primarySurface
                      : AppColors.errorSurface,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Text(
                  game.isOpen && !game.isFull ? 'ABERTA' : 'LOTADA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: game.isOpen && !game.isFull
                        ? AppColors.primary
                        : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(sportLabel,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                '$spotsLeft vagas',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(game.title, style: AppTextStyles.titleSmall),
          if (game.description != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              game.description!,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(PhosphorIcons.calendar(), size: 14, color: AppColors.primary),
              Text(
                ' $dateStr às $timeStr',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          Row(
            children: [
              Icon(PhosphorIcons.mapPin(), size: 14, color: AppColors.primary),
              Expanded(
                child: Text(
                  ' $location',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(PhosphorIcons.users(), size: 14, color: AppColors.primary),
              Text(
                ' ${game.participantCount}/${game.maxPlayers} jogadores',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const Spacer(),
              AppButtonSmall(
                label: 'Ver detalhes',
                filled: false,
                onPressed: () =>
                    context.push(AppRoutes.peladaDetailOf(game.id)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
