// lib/features/match/presentation/pages/register_result_page.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';

class RegisterResultPage extends StatefulWidget {
  const RegisterResultPage({super.key});
  @override
  State<RegisterResultPage> createState() => _RegisterResultPageState();
}

class _RegisterResultPageState extends State<RegisterResultPage> {
  int _scoreA = 3;
  int _scoreB = 1;

  final _playersA = [
    {'name': 'Carlos Souza', 'initials': 'CA', 'goals': 2, 'assists': 0},
    {'name': 'Joao Silva', 'initials': 'JO', 'goals': 1, 'assists': 1},
    {'name': 'Pedro Alves', 'initials': 'PE', 'goals': 0, 'assists': 1},
    {'name': 'Lucas Costa', 'initials': 'LU', 'goals': 0, 'assists': 0},
  ];

  final _playersB = [
    {'name': 'Andre', 'initials': 'AN', 'goals': 1, 'assists': 0},
    {'name': 'Marcos', 'initials': 'MA', 'goals': 0, 'assists': 0},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Registrar Resultado', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(children: [
            _buildScoreCard(),
            const SizedBox(height: AppSpacing.md),
            _buildGoalsCard(),
            const SizedBox(height: AppSpacing.md),
            _buildNotesCard(),
            const SizedBox(height: AppSpacing.md),
            _buildWarningCard(),
          ]),
        ),
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.modal),
            child: AppButton.primary(
              label: 'Enviar Resultado',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.home),
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
            style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.lg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          _scoreColumn('FU', AppColors.avatarGreen, 'Furacao FC', true),
          Text('X', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textDisabled)),
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
      Text(name, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
      const SizedBox(height: AppSpacing.md),
      Row(children: [
        _counterBtn(PhosphorIcons.minus(), () => setState(() {
          if (isA && _scoreA > 0) _scoreA--;
          if (!isA && _scoreB > 0) _scoreB--;
        }), false),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text('$score',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ),
        _counterBtn(PhosphorIcons.plus(), () => setState(() {
          if (isA) _scoreA++;
          else _scoreB++;
        }), true),
      ]),
    ]);
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border: Border.all(color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: filled ? AppColors.textOnPrimary : AppColors.textPrimary, size: 16),
      ),
    );
  }

  Widget _buildGoalsCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quem fez os gols? (opcional)', style: AppTextStyles.titleSmall),
        Text('Toque para adicionar gol ou assistencia',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        Text('Furacao FC', style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ..._playersA.map((p) => _playerRow(p)),
        const Divider(height: AppSpacing.xl),
        Text('Uniao Vila', style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        ..._playersB.map((p) => _playerRow(p)),
      ]),
    );
  }

  Widget _playerRow(Map<String, dynamic> player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        AppTeamAvatar(
          initials: player['initials'] as String,
          color: AppColors.avatarGreen,
          size: 36, fontSize: 12,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(player['name'] as String, style: AppTextStyles.bodyMedium)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text('Gol ${player['goals']}',
              style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text('Assist. ${player['assists']}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ),
      ]),
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
      message: 'O time adversario tera 72 horas para confirmar este resultado. Se nao responder, sera aceito automaticamente.',
    );
  }
}
