import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});
  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPosition = 'Qualquer';
  final _positions = [
    'Goleiro',
    'Zagueiro',
    'Lateral',
    'Meia',
    'Atacante',
    'Qualquer'
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Informe seu nome';
    return null;
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

  String? _validateConfirmPassword(String? value) {
    if (value != _passwordController.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final success = await ref.read(authViewModelProvider.notifier).register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
          position:
              _selectedPosition == 'Qualquer' ? null : _selectedPosition,
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.home);
    } else {
      final error = ref.read(authViewModelProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString().replaceAll('Exception: ', '') ??
              'Erro ao criar conta'),
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
          decoration:
              const BoxDecoration(gradient: AppGradients.primaryVertical),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
              child: Row(children: [
                IconButton(
                  icon: Icon(PhosphorIcons.arrowLeft(),
                      color: AppColors.textOnPrimary),
                  onPressed: () => context.pop(),
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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppInput(
                label: 'Nome completo',
                hint: 'Joao Silva',
                prefixIcon: PhosphorIcons.user(),
                controller: _nameController,
                validator: _validateName,
              ),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Confirmar senha',
                hint: '••••••••',
                prefixIcon: PhosphorIcons.lock(),
                isPassword: true,
                controller: _confirmController,
                validator: _validateConfirmPassword,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text('Posicao preferida', style: AppTextStyles.labelMedium),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _positions
                    .map((pos) => AppFilterChip(
                          label: pos,
                          selected: _selectedPosition == pos,
                          onTap: () => setState(() => _selectedPosition = pos),
                        ))
                    .toList(),
              ),
              const SizedBox(height: AppSpacing.xxl),
              AppButton.primary(
                label: isLoading ? 'Criando conta...' : 'Criar conta',
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Ja tem conta? ',
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text('Entrar',
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
