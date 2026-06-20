import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RegisterResultPage extends ConsumerStatefulWidget {
  const RegisterResultPage({required this.gameId, super.key});

  final String gameId;

  @override
  ConsumerState<RegisterResultPage> createState() =>
      _RegisterResultPageState();
}

class _RegisterResultPageState extends ConsumerState<RegisterResultPage> {
  int _goalsA = 0;
  int _goalsB = 0;
  int _assistsA = 0;
  int _assistsB = 0;

  Future<void> _submit() async {
    final match =
        ref.read(matchDetailProvider(widget.gameId)).value;
    if (match == null) return;

    final myUserId = ref.read(authViewModelProvider).value?.userId ?? '';
    final iAmA = match.teamAId == myUserId;

    final playerAGoals = iAmA ? _goalsA : _goalsB;
    final playerBGoals = iAmA ? _goalsB : _goalsA;
    final playerAAssists = iAmA ? _assistsA : _assistsB;
    final playerBAssists = iAmA ? _assistsB : _assistsA;

    final ok = await ref.read(submitResultProvider.notifier).submit(
          widget.gameId,
          playerAGoals: playerAGoals,
          playerBGoals: playerBGoals,
          playerAAssists: playerAAssists,
          playerBAssists: playerBAssists,
        );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Resultado enviado! Aguardando confirmação do adversário.'),
          backgroundColor: Colors.green,
        ),
      );
      context.pop();
    } else {
      final err = ref.read(submitResultProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(err?.toString() ?? 'Erro ao enviar resultado')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gameAsync = ref.watch(matchDetailProvider(widget.gameId));
    final isLoading = ref.watch(submitResultProvider).isLoading;
    final myUserId = ref.watch(authViewModelProvider).value?.userId ?? '';

    final sport = gameAsync.whenOrNull(
          data: (m) => _sportLabel(m.sport),
        ) ??
        'Futebol';

    final iAmA = gameAsync.whenOrNull(
          data: (m) => m.teamAId == myUserId,
        ) ??
        true;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
          title: 'Registrar Resultado — $sport',
          showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(children: [
            _buildScoreCard(iAmA),
            const SizedBox(height: AppSpacing.md),
            _buildAssistsCard(iAmA),
            const SizedBox(height: AppSpacing.md),
            const AppWarningBanner(
              message:
                  'O adversário terá 72 horas para confirmar este resultado. '
                  'Se não responder, será aceito automaticamente.',
            ),
          ]),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                color: AppColors.surface, boxShadow: AppShadows.modal),
            child: AppButton.primary(
              label: isLoading ? 'Enviando…' : 'Enviar Resultado',
              icon: isLoading ? null : PhosphorIcons.trophy(),
              onPressed: isLoading ? null : _submit,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreCard(bool iAmA) {
    return AppCard(
      child: Column(children: [
        Text('Placar final',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _scoreColumn('EU', AppColors.avatarGreen, 'Eu',
              iAmA ? _goalsA : _goalsB, true),
          Text('×',
              style: AppTextStyles.titleLarge
                  .copyWith(color: AppColors.textDisabled)),
          _scoreColumn('ADV', AppColors.avatarBlue, 'Adversário',
              iAmA ? _goalsB : _goalsA, false),
        ]),
      ]),
    );
  }

  Widget _scoreColumn(
      String initials, Color color, String label, int score, bool isMe) {
    return Column(children: [
      AppTeamAvatar(initials: initials, color: color, size: 48),
      const SizedBox(height: AppSpacing.xs),
      Text(label,
          style: AppTextStyles.bodySmall
              .copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        _counterBtn(
            PhosphorIcons.minus(),
            () => setState(() {
                  if (isMe && _goalsA > 0) _goalsA--;
                  if (!isMe && _goalsB > 0) _goalsB--;
                }),
            false),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('$score',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
        _counterBtn(
            PhosphorIcons.plus(),
            () => setState(() {
                  if (isMe) _goalsA++;
                  if (!isMe) _goalsB++;
                }),
            true),
      ]),
    ]);
  }

  Widget _buildAssistsCard(bool iAmA) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assistências (opcional)',
              style: AppTextStyles.titleSmall),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            const Expanded(
              child: Text('Eu',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            _smallCounter(
              iAmA ? _assistsA : _assistsB,
              () => setState(() {
                if (iAmA && _assistsA > 0) _assistsA--;
                if (!iAmA && _assistsB > 0) _assistsB--;
              }),
              () => setState(() {
                if (iAmA) _assistsA++;
                if (!iAmA) _assistsB++;
              }),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [
            const Expanded(
              child: Text('Adversário',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ),
            _smallCounter(
              iAmA ? _assistsB : _assistsA,
              () => setState(() {
                if (iAmA && _assistsB > 0) _assistsB--;
                if (!iAmA && _assistsA > 0) _assistsA--;
              }),
              () => setState(() {
                if (iAmA) _assistsB++;
                if (!iAmA) _assistsA++;
              }),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _smallCounter(int value, VoidCallback dec, VoidCallback inc) {
    return Row(children: [
      _counterBtn(PhosphorIcons.minus(), dec, false),
      Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text('$value',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ),
      _counterBtn(PhosphorIcons.plus(), inc, true),
    ]);
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border: Border.all(
              color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color:
                filled ? AppColors.textOnPrimary : AppColors.textPrimary,
            size: 16),
      ),
    );
  }

  String _sportLabel(String? sport) => switch (sport) {
        'futsal' => 'Futsal',
        'society' => 'Society',
        'campo' => 'Campo',
        _ => 'Futebol',
      };
}
