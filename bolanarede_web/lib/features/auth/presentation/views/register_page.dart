import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Painel esquerdo
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
                        'Comece a gerenciar seu campo hoje',
                        style: TextStyle(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          fontSize: 18,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Painel direito — stepper
          Expanded(
            flex: 3,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxxl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Criar conta',
                        style: AppTextStyles.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Preencha os dados para começar',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxxl),
                      // Step indicator
                      _buildStepIndicator(),
                      const SizedBox(height: AppSpacing.xxxl),
                      if (_currentStep == 0) _buildStep1(),
                      if (_currentStep == 1) _buildStep2(),
                      if (_currentStep == 2) _buildStep3(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Conta', 'Campo', 'Plano'];
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          return Expanded(
            child: Container(
              height: 2,
              color: i ~/ 2 < _currentStep
                  ? AppColors.primary
                  : AppColors.border,
            ),
          );
        }
        final idx = i ~/ 2;
        final isActive = idx <= _currentStep;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? AppColors.primary : AppColors.surface,
                border: Border.all(
                  color: isActive ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Center(
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              steps[idx],
              style: AppTextStyles.bodySmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInput(
          label: 'Nome completo',
          prefixIcon: PhosphorIcons.user(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Email',
          hint: 'seu@email.com',
          prefixIcon: PhosphorIcons.envelope(),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Telefone',
          hint: '(41) 99999-0000',
          prefixIcon: PhosphorIcons.phone(),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Senha',
          hint: 'Mínimo 8 caracteres',
          prefixIcon: PhosphorIcons.lock(),
          isPassword: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Confirmar senha',
          prefixIcon: PhosphorIcons.lock(),
          isPassword: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Checkbox(value: false, onChanged: (_) {}),
            Expanded(
              child: Text.rich(
                TextSpan(
                  text: 'Aceito os ',
                  style: AppTextStyles.bodySmall,
                  children: [
                    TextSpan(
                      text: 'Termos de Uso',
                      style: AppTextStyles.link.copyWith(fontSize: 12),
                    ),
                    const TextSpan(text: ' e '),
                    TextSpan(
                      text: 'Política de Privacidade',
                      style: AppTextStyles.link.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: 'Próximo',
          onPressed: () => setState(() => _currentStep = 1),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInput(
          label: 'Nome do campo',
          hint: 'Ex: Arena do Grêmio',
          prefixIcon: PhosphorIcons.soccerBall(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Cidade',
          prefixIcon: PhosphorIcons.mapPin(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Estado (UF)',
          prefixIcon: PhosphorIcons.mapPinLine(),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'CEP',
          hint: '00000-000',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Endereço completo',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppInput(
          label: 'Telefone de contato',
          prefixIcon: PhosphorIcons.phone(),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            AppButton.outline(
              label: '← Voltar',
              width: 120,
              onPressed: () => setState(() => _currentStep = 0),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppButton.primary(
                label: 'Próximo',
                onPressed: () => setState(() => _currentStep = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Escolha seu plano', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.lg),
        _planCard(
          name: 'BASIC',
          price: 'Gratuito',
          features: [
            'Gestão interna',
            'Reservas manuais',
            'CRM básico',
          ],
          isSelected: false,
        ),
        const SizedBox(height: AppSpacing.md),
        _planCard(
          name: 'PRO',
          price: 'R\$ 89/mês',
          features: [
            'Tudo do BASIC',
            'Visível no catálogo',
            'Reservas pelo app',
            'Notificações',
          ],
          isSelected: true,
          isPopular: true,
        ),
        const SizedBox(height: AppSpacing.md),
        _planCard(
          name: 'MULTI',
          price: 'R\$ 199/mês',
          features: [
            'Tudo do PRO',
            'Múltiplas quadras',
            'Relatórios avançados',
            'API de integração',
          ],
          isSelected: false,
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: [
            AppButton.outline(
              label: '← Voltar',
              width: 120,
              onPressed: () => setState(() => _currentStep = 1),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppButton.primary(
                label: 'Concluir cadastro',
                onPressed: () => context.go(AppRoutes.dashboard),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _planCard({
    required String name,
    required String price,
    required List<String> features,
    required bool isSelected,
    bool isPopular = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primarySurface : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected ? AppShadows.card : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(name, style: AppTextStyles.titleSmall),
              const Spacer(),
              Text(price, style: AppTextStyles.titleSmall),
              if (isPopular) ...[
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: const Text(
                    'Mais popular',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.check(),
                    size: 14,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(f, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
