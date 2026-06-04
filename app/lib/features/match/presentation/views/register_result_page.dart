import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RegisterResultPage extends StatefulWidget {
  const RegisterResultPage({super.key});
  @override
  State<RegisterResultPage> createState() => _RegisterResultPageState();
}

class _RegisterResultPageState extends State<RegisterResultPage> {
  int _scoreA = 0;
  int _scoreB = 0;

  // listas reativas — não são mais final
  final List<Map<String, dynamic>> _playersA = [
    {'name': 'Carlos Souza', 'initials': 'CA', 'goals': 0, 'assists': 0},
    {'name': 'Joao Silva', 'initials': 'JO', 'goals': 0, 'assists': 0},
    {'name': 'Pedro Alves', 'initials': 'PE', 'goals': 0, 'assists': 0},
    {'name': 'Lucas Costa', 'initials': 'LU', 'goals': 0, 'assists': 0},
  ];

  final List<Map<String, dynamic>> _playersB = [
    {'name': 'Andre', 'initials': 'AN', 'goals': 0, 'assists': 0},
    {'name': 'Marcos', 'initials': 'MA', 'goals': 0, 'assists': 0},
  ];

  int get _totalGoalsA =>
      _playersA.fold(0, (sum, p) => sum + (p['goals'] as int));
  int get _totalGoalsB =>
      _playersB.fold(0, (sum, p) => sum + (p['goals'] as int));

  // valida se gols individuais batem com o placar
  bool get _goalsMatchScore =>
      _totalGoalsA == _scoreA && _totalGoalsB == _scoreB;

  void _submit() {
    if (!_goalsMatchScore && (_totalGoalsA > 0 || _totalGoalsB > 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gols individuais não batem com o placar '
            '(Time A: $_totalGoalsA/$_scoreA, '
            'Time B: $_totalGoalsB/$_scoreB)',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar:
          AppGradientAppBar(title: 'Registrar Resultado', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(children: [
            _buildScoreCard(),
            const SizedBox(height: AppSpacing.md),
            if ((_totalGoalsA > 0 || _totalGoalsB > 0) && !_goalsMatchScore)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppWarningBanner(
                  message: 'Gols individuais não batem com o placar. '
                      'Time A: $_totalGoalsA/$_scoreA  '
                      'Time B: $_totalGoalsB/$_scoreB',
                ),
              ),
            _buildGoalsCard(),
            const SizedBox(height: AppSpacing.md),
            _buildNotesCard(),
            const SizedBox(height: AppSpacing.md),
            _buildWarningCard(),
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
              label: 'Enviar Resultado',
              onPressed: _submit,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildScoreCard() {
    return AppCard(
      child: Column(children: [
        Text('Placar final',
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _scoreColumn('FU', AppColors.avatarGreen, 'Furacao FC', true),
          Text('X',
              style: AppTextStyles.titleLarge
                  .copyWith(color: AppColors.textDisabled)),
          _scoreColumn('UN', AppColors.avatarBlue, 'Uniao Vila', false),
        ]),
      ]),
    );
  }

  Widget _scoreColumn(String initials, Color color, String name, bool isA) {
    final score = isA ? _scoreA : _scoreB;
    return Column(children: [
      AppTeamAvatar(initials: initials, color: color, size: 48),
      const SizedBox(height: AppSpacing.sm),
      Text(name,
          style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        _counterBtn(
            PhosphorIcons.minus(),
            () => setState(() {
                  if (isA && _scoreA > 0) _scoreA--;
                  if (!isA && _scoreB > 0) _scoreB--;
                }),
            false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('$score',
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary)),
        ),
        _counterBtn(
            PhosphorIcons.plus(),
            () => setState(() {
                  if (isA)
                    _scoreA++;
                  else
                    _scoreB++;
                }),
            true),
      ]),
    ]);
  }

  Widget _buildGoalsCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quem fez os gols? (opcional)',
            style: AppTextStyles.titleSmall),
        Text('Use + e - para marcar gols e assistencias de cada jogador',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Row(children: [
          _goalSummaryBadge('Furacao FC', _totalGoalsA, _scoreA),
          const SizedBox(width: AppSpacing.sm),
          _goalSummaryBadge('Uniao Vila', _totalGoalsB, _scoreB),
        ]),
        const SizedBox(height: AppSpacing.md),
        Text('Furacao FC',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ..._playersA.asMap().entries.map(
              (e) => _playerRow(e.value, e.key, true),
            ),
        const Divider(height: AppSpacing.xl),
        Text('Uniao Vila',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ..._playersB.asMap().entries.map(
              (e) => _playerRow(e.value, e.key, false),
            ),
      ]),
    );
  }

  Widget _goalSummaryBadge(String team, int individual, int placar) {
    final ok = individual == placar;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: ok ? AppColors.primarySurface : AppColors.errorSurface,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          '$team: $individual/$placar gols',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: ok ? AppColors.primary : AppColors.error,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _playerRow(Map<String, dynamic> player, int index, bool isTeamA) {
    final goals = player['goals'] as int;
    final assists = player['assists'] as int;
    final list = isTeamA ? _playersA : _playersB;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppTeamAvatar(
            initials: player['initials'] as String,
            color: isTeamA ? AppColors.avatarGreen : AppColors.avatarBlue,
            size: 36,
            fontSize: 12,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
              child: Text(player['name'] as String,
                  style: AppTextStyles.bodyMedium)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          const SizedBox(width: 44), // alinha com o avatar
          Text('Gols:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          _smallCounterBtn(PhosphorIcons.minus(), () {
            setState(() {
              if ((list[index]['goals'] as int) > 0) list[index]['goals']--;
            });
          }, false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('$goals',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
          _smallCounterBtn(PhosphorIcons.plus(), () {
            setState(() => list[index]['goals']++);
          }, true),
          const SizedBox(width: AppSpacing.lg),
          Text('Assist.:',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
          const SizedBox(width: AppSpacing.sm),
          _smallCounterBtn(PhosphorIcons.minus(), () {
            setState(() {
              if ((list[index]['assists'] as int) > 0) list[index]['assists']--;
            });
          }, false),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text('$assists',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
          _smallCounterBtn(PhosphorIcons.plus(), () {
            setState(() => list[index]['assists']++);
          }, true),
        ]),
      ]),
    );
  }

  Widget _smallCounterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border:
              Border.all(color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: filled ? AppColors.textOnPrimary : AppColors.textPrimary,
            size: 12),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border:
              Border.all(color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: filled ? AppColors.textOnPrimary : AppColors.textPrimary,
            size: 16),
      ),
    );
  }

  Widget _buildNotesCard() {
    return AppCard(
      child: AppInput(
        label: 'Observacoes (opcional)',
        hint: 'Algum incidente? Cartao, lesao...',
        maxLines: 3,
      ),
    );
  }

  Widget _buildWarningCard() {
    return const AppWarningBanner(
      message: 'O time adversario tera 72 horas para confirmar este resultado. '
          'Se nao responder, sera aceito automaticamente.',
    );
  }
}
