import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _selectedTab = 0;
  final _tabs = ['Perfil da conta', 'Notificações', 'Plano e faturamento', 'Integrações'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tabs laterais
        SizedBox(
          width: 220,
          child: Column(
            children: _tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final tab = entry.value;
              final isActive = _selectedTab == i;
              return ListTile(
                title: Text(
                  tab,
                  style: TextStyle(
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                tileColor: isActive ? AppColors.primarySurface : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                onTap: () => setState(() => _selectedTab = i),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: AppSpacing.xxl),
        // Conteúdo
        Expanded(
          child: _selectedTab == 0
              ? _buildProfileTab()
              : _selectedTab == 1
                  ? _buildNotificationsTab()
                  : _selectedTab == 2
                      ? _buildPlanTab()
                      : _buildIntegrationsTab(),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perfil da Conta', style: AppTextStyles.titleSmall),
          const Divider(height: AppSpacing.xl),
          AppInput(label: 'Nome completo'),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Email',
            readOnly: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Telefone',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: 'Salvar perfil',
            width: 200,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xxxl),
          const Text('Alterar Senha', style: AppTextStyles.titleSmall),
          const Divider(height: AppSpacing.xl),
          AppInput(
            label: 'Senha atual',
            isPassword: true,
            prefixIcon: PhosphorIcons.lock(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Nova senha',
            isPassword: true,
            prefixIcon: PhosphorIcons.lock(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppInput(
            label: 'Confirmar nova senha',
            isPassword: true,
            prefixIcon: PhosphorIcons.lock(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.outline(
            label: 'Alterar senha',
            width: 200,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.xxxl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.errorSurface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.warning(), color: AppColors.error, size: 20),
                const SizedBox(width: AppSpacing.md),
                const Expanded(
                  child: Text(
                    'Excluir conta\nEsta ação é irreversível.',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
                AppButton.danger(
                  label: 'Excluir conta',
                  width: 160,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Preferências de Notificação', style: AppTextStyles.titleSmall),
          const Divider(height: AppSpacing.xl),
          _switchRow('Nova reserva pelo app', true),
          _switchRow('Reserva cancelada', true),
          _switchRow('Slot de plano recorrente liberado', true),
          _switchRow('Novo cliente cadastrado', false),
          _switchRow('Relatório semanal por email', true),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: 'Salvar preferências',
            width: 200,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _switchRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Switch(
            value: value,
            onChanged: (_) {},
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanTab() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Plano Atual', style: AppTextStyles.titleSmall),
          const Divider(height: AppSpacing.xl),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.primarySurface,
              borderRadius: AppRadius.cardRadius,
              border: Border.all(color: AppColors.primary),
            ),
            child: Row(
              children: [
                Icon(PhosphorIcons.crown(), color: AppColors.primary, size: 32),
                const SizedBox(width: AppSpacing.lg),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plano PRO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      Text('R\$ 89/mês • Vence em 31/12/2026'),
                    ],
                  ),
                ),
                AppButton.outline(
                  label: 'Gerenciar assinatura',
                  width: 200,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationsTab() {
    return Column(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('API Key', style: AppTextStyles.titleSmall),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'sk_live_••••••••••••••••••••••••••••',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  AppButton.outline(
                    label: 'Copiar',
                    width: 100,
                    height: AppSizes.buttonHeightSmall,
                    onPressed: () {},
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton.outline(
                    label: 'Revogar',
                    width: 100,
                    height: AppSizes.buttonHeightSmall,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Link público de reservas',
                style: AppTextStyles.titleSmall,
              ),
              const Divider(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'https://bolanarede.app/campo/arena-001',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  AppButton.outline(
                    label: 'Copiar',
                    width: 100,
                    height: AppSizes.buttonHeightSmall,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Row(
            children: [
              Icon(
                PhosphorIcons.whatsappLogo(),
                color: AppColors.textDisabled,
                size: 32,
              ),
              const SizedBox(width: AppSpacing.lg),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WhatsApp Business',
                      style: AppTextStyles.bodyMedium,
                    ),
                    Text(
                      'Em breve',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
