import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});
  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe seu e-mail';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'E-mail inválido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authViewModelProvider.notifier).login(
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      final error = ref.read(authViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              error?.toString().replaceAll('Exception: ', '') ?? 'Erro ao entrar'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authViewModelProvider).isLoading;

    return Scaffold(
      body: Column(children: [
        Container(
          width: double.infinity,
          height: 220,
          decoration:
              const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
            ]),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppInput(
                label: 'E-mail',
                hint: 'seu@email.com',
                prefixIcon: PhosphorIcons.envelope(),
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                validator: _validateEmail,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Senha',
                hint: '••••••••',
                prefixIcon: PhosphorIcons.lock(),
                isPassword: true,
                controller: _passwordController,
                validator: _validatePassword,
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => showComingSoon(context),
                  child: const Text('Esqueci minha senha'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: isLoading ? 'Entrando...' : 'Entrar',
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text('ou',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.textDisabled)),
                ),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: AppSizes.buttonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => showComingSoon(context),
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
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Nao tem conta? ',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.register),
                  child: Text('Criar conta',
                      style: AppTextStyles.link
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
            ),
          ),
        ),
      ]),
    );
  }
}
