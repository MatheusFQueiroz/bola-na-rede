import 'package:flutter/material.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header gradiente
          Container(
            width: double.infinity,
            height: 220,
            decoration: const BoxDecoration(
                gradient: AppGradients.primaryVertical),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(PhosphorIcons.soccerBall(),
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Bem-vindo de volta',
                      style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ],
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
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Esqueci minha senha'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton.primary(
                    label: 'Entrar',
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.home),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  // Divisor
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: Text('ou',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.textDisabled)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: AppSpacing.xl),
                  // Google
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.buttonRadius),
                      ),
                      icon: Icon(PhosphorIcons.googleLogo(),
                          size: 24, color: AppColors.textPrimary),
                      label: const Text('Continuar com Google'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  // Rodapé
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('Nao tem conta? ',
                        style: AppTextStyles.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.register),
                      child: Text('Criar conta',
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
