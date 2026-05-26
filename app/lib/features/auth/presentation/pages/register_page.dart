import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import '../viewmodels/auth_viewmodel.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    final success = await context.read<AuthViewModel>().register(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text,
        );

    if (!mounted) return;

    if (success) {
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (_) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              context.read<AuthViewModel>().error ?? 'Erro ao criar conta'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        context.watch<AuthViewModel>().state == AuthViewState.loading;

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
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppInput(
                label: 'Nome completo',
                hint: 'Joao Silva',
                prefixIcon: PhosphorIcons.user(),
                controller: _nameController,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'E-mail',
                hint: 'seu@email.com',
                prefixIcon: PhosphorIcons.envelope(),
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Senha',
                hint: '••••••••',
                prefixIcon: PhosphorIcons.lock(),
                isPassword: true,
                controller: _passwordController,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppInput(
                label: 'Confirmar senha',
                hint: '••••••••',
                prefixIcon: PhosphorIcons.lock(),
                isPassword: true,
                controller: _confirmController,
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
                  onTap: () => Navigator.pop(context),
                  child: Text('Entrar',
                      style: AppTextStyles.link
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ]),
    );
  }
}
