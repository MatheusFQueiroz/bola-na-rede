import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/social/presentation/viewmodels/review_viewmodel.dart';
import 'package:bola_na_rede/shared/utils/error_utils.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RatePlayersPage extends ConsumerStatefulWidget {
  const RatePlayersPage({
    required this.gameId,
    required this.opponentId,
    super.key,
  });

  final String gameId;
  final String opponentId;

  @override
  ConsumerState<RatePlayersPage> createState() => _RatePlayersPageState();
}

class _RatePlayersPageState extends ConsumerState<RatePlayersPage> {
  int _score = 3;
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(reviewViewModelProvider.notifier).submit(
          gameId: widget.gameId,
          gameType: 'game',
          revieweeUserId: widget.opponentId,
          score: _score,
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
        );

    if (!mounted) return;

    final reviewState = ref.read(reviewViewModelProvider);
    if (!reviewState.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avaliação enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRoutes.matchList);
    } else {
      final msg = errorMessage(
        reviewState.error,
        fallback: 'Erro ao enviar avaliação. Tente novamente.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reviewViewModelProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppGradientAppBar(
        title: 'Avaliar Adversário',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xxl),
            const AppTeamAvatar(
              initials: 'ADV',
              color: AppColors.avatarBlue,
              size: 80,
              fontSize: 22,
            ),
            const SizedBox(height: AppSpacing.lg),
            const Text(
              'Como foi sua experiência com o adversário?',
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _buildStarRow(),
            const SizedBox(height: AppSpacing.xxl),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Comentário opcional...',
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: AppSpacing.xxl),
            AppButton.primary(
              label: isLoading ? 'Enviando…' : 'Enviar Avaliação',
              onPressed: isLoading ? null : _submit,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(
              onPressed:
                  isLoading ? null : () => context.go(AppRoutes.matchList),
              child: const Text('Pular'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final filled = index < _score;
        return GestureDetector(
          onTap: () => setState(() => _score = index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(
              filled
                  ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                  : PhosphorIcons.star(),
              color: filled
                  ? const Color(0xFFF59E0B)
                  : AppColors.textDisabled,
              size: 36,
            ),
          ),
        );
      }),
    );
  }
}
