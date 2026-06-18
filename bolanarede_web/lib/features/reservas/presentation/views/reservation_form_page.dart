import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/shared/snapshots.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';
import 'package:bolanarede_web/data/mocks/mock_data.dart';
import 'package:bolanarede_web/features/campos/domain/entities/field.dart';
import 'package:bolanarede_web/features/reservas/domain/entities/reservation.dart';
import 'package:bolanarede_web/shared/widgets/web_components.dart';

class ReservationFormPage extends StatefulWidget {
  const ReservationFormPage({super.key});

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  // Seleções
  Field? _selectedField;
  FieldCourt? _selectedCourt;
  DateTime? _selectedDate;
  String? _selectedStartTime;
  String? _selectedEndTime;
  ReservationChannel _selectedChannel = ReservationChannel.manual;
  BookerType _selectedBookerType = BookerType.player;

  bool _isLoading = false;

  // Preço calculado com base nas regras do campo selecionado
  double? _calculatedPrice;

  // Slots de horário disponíveis
  final List<String> _timeSlots = List.generate(
    15,
    (i) => '${(8 + i).toString().padLeft(2, '0')}:00',
  );

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Recalcula preço quando campo, horário ou data mudam
  void _recalculatePrice() {
    if (_selectedField == null ||
        _selectedStartTime == null ||
        _selectedEndTime == null) {
      setState(() => _calculatedPrice = null);
      return;
    }

    final rules = MockData.pricingRules[_selectedField!.id] ?? [];
    if (rules.isEmpty) {
      setState(() => _calculatedPrice = null);
      return;
    }

    // Tenta encontrar regra para o dia da semana e horário selecionados
    final dayOfWeek = _selectedDate?.weekday; // 1=Seg … 7=Dom
    // Converte para o padrão do mock (0=Dom … 6=Sáb)
    final mockDow = dayOfWeek != null ? dayOfWeek % 7 : null;

    PricingRule? matchedRule;
    for (final rule in rules) {
      if (!rule.isActive) continue;
      if (rule.dayOfWeek == null ||
          (mockDow != null && rule.dayOfWeek!.contains(mockDow))) {
        matchedRule = rule;
        break;
      }
    }

    // Calcula duração em horas
    if (matchedRule != null &&
        _selectedStartTime != null &&
        _selectedEndTime != null) {
      final startH = int.parse(_selectedStartTime!.split(':')[0]);
      final endH = int.parse(_selectedEndTime!.split(':')[0]);
      final hours = (endH - startH).clamp(0, 24);
      setState(() => _calculatedPrice = matchedRule!.price * hours);
    } else if (rules.isNotEmpty) {
      setState(() => _calculatedPrice = rules.first.price);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      locale: const Locale('pt', 'BR'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _recalculatePrice();
      });
    }
  }

  String _formatDate(DateTime date) {
    final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    final dayName = days[date.weekday - 1];
    return '$dayName, ${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _channelLabel(ReservationChannel c) {
    switch (c) {
      case ReservationChannel.manual:
        return 'Manual';
      case ReservationChannel.whatsapp:
        return 'WhatsApp';
      case ReservationChannel.phone:
        return 'Telefone';
      case ReservationChannel.link:
        return 'Link';
      case ReservationChannel.bolanarededbApp:
        return 'App BolaNaRede';
    }
  }

  String _bookerTypeLabel(BookerType t) {
    switch (t) {
      case BookerType.player:
        return 'Jogador individual';
      case BookerType.team:
        return 'Time';
      case BookerType.group:
        return 'Grupo / Pelada';
    }
  }

  Future<void> _submit() async {
    // Valida o formulário
    if (!_formKey.currentState!.validate()) return;

    // Validações extras que não cabem no TextFormField
    if (_selectedField == null) {
      _showError('Selecione um campo.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Selecione a data da reserva.');
      return;
    }
    if (_selectedStartTime == null || _selectedEndTime == null) {
      _showError('Selecione o horário de início e fim.');
      return;
    }
    final startH = int.parse(_selectedStartTime!.split(':')[0]);
    final endH = int.parse(_selectedEndTime!.split(':')[0]);
    if (endH <= startH) {
      _showError('O horário de fim deve ser depois do início.');
      return;
    }

    setState(() => _isLoading = true);

    // Simula chamada à API
    await Future<void>.delayed(const Duration(milliseconds: 900));

    // Monta a reserva (em produção seria enviada ao repositório)
    final newReservation = Reservation(
      id: 'res-${DateTime.now().millisecondsSinceEpoch}',
      fieldId: _selectedField!.id,
      courtId: _selectedCourt?.id,
      channel: _selectedChannel,
      bookerSnapshot: BookerSnapshot(
        name: _nameController.text.trim(),
        type: _selectedBookerType,
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
      date: _selectedDate!,
      startTime: _selectedStartTime!,
      endTime: _selectedEndTime!,
      price: _calculatedPrice ?? 0,
      platformFeePct:
          _selectedChannel == ReservationChannel.bolanarededbApp ? 6 : 0,
      platformFeeAmt: _selectedChannel == ReservationChannel.bolanarededbApp
          ? (_calculatedPrice ?? 0) * 0.06
          : 0,
      netAmount: _selectedChannel == ReservationChannel.bolanarededbApp
          ? (_calculatedPrice ?? 0) * 0.94
          : (_calculatedPrice ?? 0),
      status: ReservationStatus.confirmed,
      paymentStatus: PaymentStatus.unpaid,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Adiciona ao mock em memória
    MockData.reservations.add(newReservation);

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccess();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(PhosphorIcons.warning(), color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(PhosphorIcons.checkCircle(), color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            const Text('Reserva criada com sucesso!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
    context.go('/dashboard/reservations');
  }

  @override
  Widget build(BuildContext context) {
    final availableCourts = _selectedField != null
    ? (MockData.courts[_selectedField!.id] ?? <FieldCourt>[])
    : <FieldCourt>[];

    final endTimeOptions = _selectedStartTime != null
        ? _timeSlots
            .where(
              (t) => int.parse(t.split(':')[0]) >
                  int.parse(_selectedStartTime!.split(':')[0]),
            )
            .toList()
        : <String>[];

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: Icon(PhosphorIcons.arrowLeft()),
                onPressed: () => context.go('/dashboard/reservations'),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Expanded(
                child: Text('Nova Reserva', style: AppTextStyles.titleLarge),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Formulário (60%)
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Seção: Dados do Horário
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dados do Horário',
                            style: AppTextStyles.titleSmall,
                          ),
                          const Divider(height: AppSpacing.xl),

                          // Campo
                          const Text('Campo *', style: AppTextStyles.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<Field>(
                            value: _selectedField,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.inputRadius,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            hint: const Text('Selecione o campo'),
                            items: MockData.fields
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f.name),
                                  ),
                                )
                                .toList(),
                            onChanged: (field) {
                              setState(() {
                                _selectedField = field;
                                _selectedCourt = null;
                                _recalculatePrice();
                              });
                            },
                            validator: (v) =>
                                v == null ? 'Selecione um campo' : null,
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Quadra
                          const Text('Quadra', style: AppTextStyles.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<FieldCourt>(
                            value: _selectedCourt,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.inputRadius,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            hint: Text(
                              _selectedField == null
                                  ? 'Selecione um campo primeiro'
                                  : availableCourts.isEmpty
                                      ? 'Nenhuma quadra cadastrada'
                                      : 'Selecione a quadra (opcional)',
                            ),
                            items: availableCourts
                                .map(
                                  (c) => DropdownMenuItem<FieldCourt>(
                                    value: c,
                                    child: Text(c.name),
                                  ),
                                )
                                .toList(),
                            onChanged: _selectedField == null
                                ? null
                                : (court) =>
                                    setState(() => _selectedCourt = court),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Data
                          const Text('Data *', style: AppTextStyles.labelMedium),
                          const SizedBox(height: AppSpacing.sm),
                          GestureDetector(
                            onTap: _pickDate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.border),
                                borderRadius: AppRadius.inputRadius,
                                color: AppColors.surface,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.calendarBlank(),
                                    size: 18,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    _selectedDate != null
                                        ? _formatDate(_selectedDate!)
                                        : 'Selecione a data',
                                    style: _selectedDate != null
                                        ? AppTextStyles.bodyLarge
                                        : AppTextStyles.bodyLarge.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          // Horários
                          Row(
                            children: [
                              // Início
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Início *',
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    DropdownButtonFormField<String>(
                                      value: _selectedStartTime,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.inputRadius,
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                      hint: const Text('--:--'),
                                      items: _timeSlots
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(t),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (t) {
                                        setState(() {
                                          _selectedStartTime = t;
                                          _selectedEndTime = null;
                                          _recalculatePrice();
                                        });
                                      },
                                      validator: (v) =>
                                          v == null ? 'Obrigatório' : null,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.lg),
                              // Fim
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fim *',
                                      style: AppTextStyles.labelMedium,
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    DropdownButtonFormField<String>(
                                      value: _selectedEndTime,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(
                                          borderRadius: AppRadius.inputRadius,
                                          borderSide: const BorderSide(
                                            color: AppColors.border,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg,
                                          vertical: AppSpacing.md,
                                        ),
                                      ),
                                      hint: Text(
                                        _selectedStartTime == null
                                            ? 'Selecione o início'
                                            : '--:--',
                                      ),
                                      items: endTimeOptions
                                          .map(
                                            (t) => DropdownMenuItem(
                                              value: t,
                                              child: Text(t),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: _selectedStartTime == null
                                          ? null
                                          : (t) {
                                              setState(() {
                                                _selectedEndTime = t;
                                                _recalculatePrice();
                                              });
                                            },
                                      validator: (v) =>
                                          v == null ? 'Obrigatório' : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          // Preço calculado
                          if (_calculatedPrice != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: AppColors.primarySurface,
                                borderRadius: AppRadius.cardRadius,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    PhosphorIcons.currencyCircleDollar(),
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'Valor estimado: R\$ ${_calculatedPrice!.toStringAsFixed(2)}',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Seção: Dados do Cliente
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dados do Cliente',
                            style: AppTextStyles.titleSmall,
                          ),
                          const Divider(height: AppSpacing.xl),

                          // Tipo de cliente
                          const Text(
                            'Tipo *',
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<BookerType>(
                            value: _selectedBookerType,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.inputRadius,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            items: BookerType.values
                                .map(
                                  (t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(_bookerTypeLabel(t)),
                                  ),
                                )
                                .toList(),
                            onChanged: (t) =>
                                setState(() => _selectedBookerType = t!),
                          ),
                          const SizedBox(height: AppSpacing.lg),

                          AppInput(
                            label: 'Nome *',
                            hint: 'Nome do responsável pela reserva',
                            controller: _nameController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o nome';
                              }
                              if (v.trim().length < 3) {
                                return 'Nome muito curto';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppInput(
                            label: 'Telefone *',
                            hint: '(41) 99999-0000',
                            prefixIcon: PhosphorIcons.phone(),
                            keyboardType: TextInputType.phone,
                            controller: _phoneController,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe o telefone';
                              }
                              final digits =
                                  v.replaceAll(RegExp(r'\D'), '');
                              if (digits.length < 10) {
                                return 'Telefone inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppInput(
                            label: 'Email',
                            hint: 'opcional',
                            prefixIcon: PhosphorIcons.envelope(),
                            keyboardType: TextInputType.emailAddress,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Seção: Canal e Notas
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Canal de Origem',
                            style: AppTextStyles.titleSmall,
                          ),
                          const Divider(height: AppSpacing.xl),
                          const Text(
                            'Canal *',
                            style: AppTextStyles.labelMedium,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          DropdownButtonFormField<ReservationChannel>(
                            value: _selectedChannel,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: AppRadius.inputRadius,
                                borderSide:
                                    const BorderSide(color: AppColors.border),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                            ),
                            items: ReservationChannel.values
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_channelLabel(c)),
                                  ),
                                )
                                .toList(),
                            onChanged: (c) =>
                                setState(() => _selectedChannel = c!),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppInput(
                            label: 'Notas internas',
                            hint: 'Observações sobre esta reserva...',
                            maxLines: 3,
                            controller: _notesController,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xl),

              // Resumo (40%)
              Expanded(
                flex: 2,
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resumo da Reserva',
                        style: AppTextStyles.titleSmall,
                      ),
                      const Divider(height: AppSpacing.xl),
                      _summaryRow(
                        PhosphorIcons.soccerBall(),
                        _selectedField?.name ?? '—',
                      ),
                      if (_selectedCourt != null)
                        _summaryRow(
                          PhosphorIcons.soccerBall(),
                          _selectedCourt!.name,
                        ),
                      _summaryRow(
                        PhosphorIcons.calendarBlank(),
                        _selectedDate != null
                            ? _formatDate(_selectedDate!)
                            : '—',
                      ),
                      _summaryRow(
                        PhosphorIcons.clock(),
                        _selectedStartTime != null && _selectedEndTime != null
                            ? '$_selectedStartTime – $_selectedEndTime'
                            : '—',
                      ),
                      _summaryRow(
                        PhosphorIcons.user(),
                        _nameController.text.isEmpty
                            ? '—'
                            : _nameController.text,
                      ),
                      _summaryRow(
                        PhosphorIcons.chatCircle(),
                        _channelLabel(_selectedChannel),
                      ),
                      const Divider(height: AppSpacing.xl),
                      if (_calculatedPrice != null) ...[
                        Row(
                          children: [
                            const Text(
                              'Total:',
                              style: AppTextStyles.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${_calculatedPrice!.toStringAsFixed(2)}',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (_selectedChannel ==
                            ReservationChannel.bolanarededbApp) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Taxa plataforma (6%): R\$ ${(_calculatedPrice! * 0.06).toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            'Valor líquido: R\$ ${(_calculatedPrice! * 0.94).toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          'Selecione campo e horário para calcular o valor',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                      AppButton.primary(
                        label: 'Criar Reserva',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: TextButton(
                          onPressed: () =>
                              context.go('/dashboard/reservations'),
                          child: const Text('Cancelar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}