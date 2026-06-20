import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  const CreateMatchPage({super.key});

  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> {
  String _sport = 'futsal';

  static const _sports = [
    ('futsal', 'Futsal', 'Quadra coberta · 5x5'),
    ('society', 'Society', 'Campo gramado · 7x7'),
    ('campo', 'Campo', 'Campo oficial · 11x11'),
  ];

  Future<void> _buscar() async {
    final ok = await ref
        .read(createMatchRequestProvider.notifier)
        .submit(_sport);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Solicitação enviada! Buscando adversário…'),
          backgroundColor: Colors.green,
        ),
      );
      context.go(AppRoutes.matchList);
    } else {
      final err = ref.read(createMatchRequestProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err?.toString() ?? 'Erro ao buscar partida')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createMatchRequestProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Buscar Partida', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Modalidade'),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Escolha o tipo de jogo e entraremos em fila para encontrar um adversário.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              ..._sports.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _sportCard(s.$1, s.$2, s.$3),
                  )),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                color: AppColors.primarySurface,
                child: Row(children: [
                  Icon(PhosphorIcons.info(), color: AppColors.primary, size: 18),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'O sistema encontra automaticamente um adversário com nível compatível. '
                      'Você receberá uma notificação quando a partida for confirmada.',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ]),
              ),
            ],
          ),
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
              label: isLoading ? 'Buscando…' : 'Buscar Adversário',
              icon: isLoading ? null : PhosphorIcons.magnifyingGlass(),
              onPressed: isLoading ? null : _buscar,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: AppTextStyles.labelMedium
            .copyWith(color: AppColors.textSecondary),
      );

  Widget _sportCard(String value, String title, String subtitle) {
    final selected = _sport == value;
    return GestureDetector(
      onTap: () => setState(() => _sport = value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 1,
          ),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Row(children: [
          Icon(
            PhosphorIcons.soccerBall(),
            color: selected ? AppColors.primary : AppColors.textSecondary,
            size: AppSizes.iconLg,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary),
              ),
              Text(subtitle,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ]),
          ),
          if (selected)
            Icon(PhosphorIcons.checkCircle(PhosphorIconsStyle.fill),
                color: AppColors.primary),
        ]),
      ),
    );
  }
}
