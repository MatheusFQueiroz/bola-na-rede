import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String _selectedPosition = 'Qualquer';
  final _positions = ['Goleiro', 'Zagueiro', 'Lateral', 'Meia', 'Atacante', 'Qualquer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                gradient: AppGradients.primaryVertical),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
                child: Row(children: [
                  IconButton(
                    icon: Icon(PhosphorIcons.arrowLeft(),
                        color: AppColors.textOnPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text('Criar sua conta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textOnPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),
            ),
          ),
          // Formulário
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppInput(
                    label: 'Nome completo',
                    hint: 'Joao Silva',
                    prefixIcon: PhosphorIcons.user(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput(
                    label: 'E-mail',
                    hint: 'seu@email.com',
                    prefixIcon: PhosphorIcons.envelope(),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput(
                    label: 'Senha',
                    hint: '••••••••',
                    prefixIcon: PhosphorIcons.lock(),
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppInput(
                    label: 'Confirmar senha',
                    hint: '••••••••',
                    prefixIcon: PhosphorIcons.lock(),
                    isPassword: true,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Posicao preferida',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: _positions.map((pos) {
                      return AppFilterChip(
                        label: pos,
                        selected: _selectedPosition == pos,
                        onTap: () =>
                            setState(() => _selectedPosition = pos),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton.primary(
                    label: 'Criar conta',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.home),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Ja tem conta? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text('Entrar',
                          style: AppTextStyles.link
                              .copyWith(fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
