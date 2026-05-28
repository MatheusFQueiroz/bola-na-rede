import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class CreateTeamPage extends StatefulWidget {
  const CreateTeamPage({super.key});
  @override
  State<CreateTeamPage> createState() => _CreateTeamPageState();
}

class _CreateTeamPageState extends State<CreateTeamPage> {
  Color _selectedColor = AppColors.avatarGreen;
  final _colors = [
    AppColors.avatarGreen,
    AppColors.avatarBlue,
    AppColors.avatarRed,
    AppColors.avatarOrange,
    AppColors.avatarPurple,
    AppColors.avatarTeal,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Criar Time', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Upload logo
              Center(
                child: Column(children: [
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.border,
                            width: 2,
                            style: BorderStyle.solid),
                      ),
                      child: Icon(PhosphorIcons.camera(),
                          color: AppColors.primary, size: 28),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text('Adicionar foto',
                      style: TextStyle(color: AppColors.primary, fontSize: 13)),
                ]),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppInput(
                label: 'Nome do time',
                hint: 'Ex: Furacao FC',
                prefixIcon: PhosphorIcons.users(),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Cidade',
                hint: 'Ex: Sao Paulo, SP',
                prefixIcon: PhosphorIcons.mapPin(),
              ),
              const SizedBox(height: AppSpacing.lg),
              const AppInput(
                label: 'Descricao (opcional)',
                hint: 'Fale sobre o seu time...',
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: AppSpacing.xl),
              const Text('Cor do avatar', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _colors.map((c) {
                    final selected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: selected
                            ? Icon(PhosphorIcons.check(),
                                color: AppColors.textOnPrimary, size: 18)
                            : null,
                      ),
                    );
                  }).toList()),
              const SizedBox(height: AppSpacing.xl),
              const AppWarningBanner(
                message:
                    'Seu time precisa de pelo menos 5 jogadores para disputar partidas. Convide membros apos criar o time.',
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: 'Criar Time',
                onPressed: () =>
                    context.push(AppRoutes.teamManage),
              ),
            ]),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: AppColors.background,
            child: Text(
              'Ao criar um time, voce sera automaticamente o capitao.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ),
      ]),
    );
  }
}
