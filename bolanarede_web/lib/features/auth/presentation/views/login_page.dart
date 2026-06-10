import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _isLoading = false);
      context.go(AppRoutes.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Painel esquerdo — gradiente verde
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppGradients.primaryVertical,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xxxl),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.soccerBall(),
                        size: 80,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const Text(
                        'BolaNaRede',
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Field Manager',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      Text(
                        'Gerencie seu campo com inteligência',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Mais de 500 campos confiam no BolaNaRede',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Painel direito — formulário
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Bem-vindo de volta',
                          style: AppTextStyles.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Acesse o painel do seu campo',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        AppInput(
                          label: 'Email',
                          hint: 'seu@email.com',
                          prefixIcon: PhosphorIcons.envelope(),
                          keyboardType: TextInputType.emailAddress,
                          controller: _emailController,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe seu email';
                            }
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        AppInput(
                          label: 'Senha',
                          hint: '••••••••',
                          prefixIcon: PhosphorIcons.lock(),
                          isPassword: true,
                          controller: _passwordController,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe sua senha';
                            }
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            return null;
                          },
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
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              child: Text(
                                'ou',
                                style: AppTextStyles.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton.outline(
                          label: 'Continuar com Google',
                          icon: PhosphorIcons.googleLogo(),
                          onPressed: () {},
                        ),
                        const SizedBox(height: AppSpacing.xxxl),
                        Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'Não tem conta? ',
                              style: AppTextStyles.bodyMedium,
                              children: [
                                TextSpan(
                                  text: 'Cadastrar campo',
                                  style: AppTextStyles.link,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
