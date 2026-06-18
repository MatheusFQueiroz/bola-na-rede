import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/campos/domain/entities/field.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class FieldFormPage extends StatefulWidget {
  final String? fieldId;

  const FieldFormPage({super.key, this.fieldId});

  bool get isEditing => fieldId != null;

  @override
  State<FieldFormPage> createState() => _FieldFormPageState();
}

class _FieldFormPageState extends State<FieldFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  FieldPlan _selectedPlan = FieldPlan.basic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pré-preenche os campos se estiver editando
    if (widget.isEditing) {
      final field = MockData.fields
          .where((f) => f.id == widget.fieldId)
          .firstOrNull;
      if (field != null) _populateFromField(field);
    }
  }

  void _populateFromField(Field field) {
    _nameController.text = field.name;
    _descriptionController.text = field.description ?? '';
    _phoneController.text = field.contactPhone ?? '';
    _emailController.text = field.contactEmail ?? '';
    _cepController.text = field.zipCode ?? '';
    _streetController.text = field.street ?? '';
    _cityController.text = field.city;
    _stateController.text = field.state;
    _selectedPlan = field.plan;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (widget.isEditing) {
      // Atualiza o campo existente no mock
      final index =
          MockData.fields.indexWhere((f) => f.id == widget.fieldId);
      if (index != -1) {
        final existing = MockData.fields[index];
        MockData.fields[index] = Field(
          id: existing.id,
          ownerUserId: existing.ownerUserId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          street: _streetController.text.trim().isEmpty
              ? null
              : _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim().toUpperCase(),
          zipCode: _cepController.text.trim().isEmpty
              ? null
              : _cepController.text.trim(),
          contactPhone: _phoneController.text.trim().isEmpty
              ? null
              : _phoneController.text.trim(),
          contactEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          coverPhotoUrl: existing.coverPhotoUrl,
          status: existing.status,
          plan: _selectedPlan,
          planExpiresAt: existing.planExpiresAt,
          createdAt: existing.createdAt,
          updatedAt: DateTime.now(),
        );
      }
    } else {
      // Cria novo campo no mock
      final newField = Field(
        id: 'field-${DateTime.now().millisecondsSinceEpoch}',
        ownerUserId: 'user-001',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        street: _streetController.text.trim().isEmpty
            ? null
            : _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim().toUpperCase(),
        zipCode: _cepController.text.trim().isEmpty
            ? null
            : _cepController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        coverPhotoUrl: null,
        status: FieldStatus.active,
        plan: _selectedPlan,
        planExpiresAt: _selectedPlan != FieldPlan.basic
            ? DateTime.now().add(const Duration(days: 365))
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      MockData.fields.add(newField);
    }

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                PhosphorIcons.checkCircle(),
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.isEditing
                    ? 'Campo atualizado com sucesso!'
                    : 'Campo cadastrado com sucesso!',
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ),
      );
      context.go('/dashboard/fields');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isEditing ? 'Editar Campo' : 'Cadastrar Campo',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Campos > ${widget.isEditing ? 'Editar' : 'Cadastrar'} campo',
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Informações Básicas
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informações Básicas',
                  style: AppTextStyles.titleSmall,
                ),
                const Divider(height: AppSpacing.xl),
                AppInput(
                  label: 'Nome do campo *',
                  hint: 'Ex: Arena do Grêmio',
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe o nome do campo';
                    }
                    if (v.trim().length < 3) return 'Nome muito curto';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppInput(
                  label: 'Descrição',
                  hint: 'Descreva seu campo, diferenciais, estrutura...',
                  maxLines: 3,
                  maxLength: 500,
                  controller: _descriptionController,
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppInput(
                        label: 'Telefone de contato *',
                        prefixIcon: PhosphorIcons.phone(),
                        keyboardType: TextInputType.phone,
                        hint: '(41) 99999-0000',
                        controller: _phoneController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o telefone';
                          }
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) return 'Telefone inválido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppInput(
                        label: 'Email de contato',
                        prefixIcon: PhosphorIcons.envelope(),
                        keyboardType: TextInputType.emailAddress,
                        hint: 'contato@campo.com',
                        controller: _emailController,
                        validator: (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              !v.contains('@')) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: AppInput(
                        label: 'CEP',
                        hint: '00000-000',
                        controller: _cepController,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 3,
                      child: AppInput(
                        label: 'Endereço completo *',
                        hint: 'Rua, número, bairro',
                        controller: _streetController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o endereço';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: AppInput(
                        label: 'Cidade *',
                        controller: _cityController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe a cidade';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      flex: 1,
                      child: AppInput(
                        label: 'Estado *',
                        hint: 'PR',
                        controller: _stateController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe o estado';
                          }
                          if (v.trim().length != 2) {
                            return 'Use a sigla (ex: PR)';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Plano
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Plano', style: AppTextStyles.titleSmall),
                const Divider(height: AppSpacing.xl),
                ...FieldPlan.values.map(
                  (plan) => _PlanOption(
                    plan: plan,
                    isSelected: _selectedPlan == plan,
                    onTap: () => setState(() => _selectedPlan = plan),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),

          // Botões
          Row(
            children: [
              AppButton.outline(
                label: 'Cancelar',
                width: 140,
                onPressed: () => context.go('/dashboard/fields'),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: AppButton.primary(
                  label: widget.isEditing ? 'Salvar alterações' : 'Cadastrar campo',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanOption extends StatelessWidget {
  final FieldPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanOption({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  String get _name => plan.name.toUpperCase();

  String get _price {
    switch (plan) {
      case FieldPlan.basic:
        return 'Gratuito';
      case FieldPlan.pro:
        return 'R\$ 89/mês';
      case FieldPlan.multi:
        return 'R\$ 199/mês';
    }
  }

  List<String> get _features {
    switch (plan) {
      case FieldPlan.basic:
        return ['Gestão interna', 'Reservas manuais', 'CRM básico'];
      case FieldPlan.pro:
        return [
          'Tudo do BASIC',
          'Visível no catálogo BolaNaRede',
          'Reservas pelo app',
          'Notificações push',
        ];
      case FieldPlan.multi:
        return [
          'Tudo do PRO',
          'Múltiplas quadras',
          'Relatórios avançados',
          'API de integração',
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<FieldPlan>(
              value: plan,
              groupValue: isSelected ? plan : null,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_name, style: AppTextStyles.titleSmall),
                      const Spacer(),
                      Text(
                        _price,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ..._features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Row(
                        children: [
                          Icon(
                            PhosphorIcons.check(),
                            size: 12,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(f, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}