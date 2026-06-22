import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/peladas/presentation/viewmodels/open_game_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class CreatePeladaPage extends ConsumerStatefulWidget {
  const CreatePeladaPage({super.key});

  @override
  ConsumerState<CreatePeladaPage> createState() => _CreatePeladaPageState();
}

class _CreatePeladaPageState extends ConsumerState<CreatePeladaPage> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _sport = 'futsal';
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  int _duration = 90;
  int _minPlayers = 10;
  int _maxPlayers = 22;

  // Task 7: field selection
  String? _selectedFieldId;
  String? _selectedFieldName;
  String? _selectedFieldAddress;

  // Task 8: recurring pelada
  bool _isRecurring = false;
  int _recurringWeeks = 4;
  int _recurringDayOfWeek = 2;
  static const _weekDayLabels = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  String get _scheduledAtIso {
    final dt = DateTime(
      _scheduledAt.year,
      _scheduledAt.month,
      _scheduledAt.day,
      _time.hour,
      _time.minute,
    );
    return dt.toUtc().toIso8601String();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledAt = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickField() async {
    final result = await context.push<Map<String, String>>(AppRoutes.fieldPicker);
    if (result != null) {
      setState(() {
        _selectedFieldId = result['id'];
        _selectedFieldName = result['name'];
        _selectedFieldAddress = result['address'];
      });
    }
  }

  Future<void> _submit() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o título da pelada.')),
      );
      return;
    }
    if (_isRecurring) {
      await _submitRecurring();
    } else {
      await _submitSingle(_scheduledAtIso);
    }
  }

  Future<void> _submitSingle(String scheduledAt) async {
    final created = await ref.read(createOpenGameProvider.notifier).create(
          title: _titleCtrl.text.trim(),
          sport: _sport,
          scheduledAt: scheduledAt,
          durationMinutes: _duration,
          minPlayers: _minPlayers,
          maxPlayers: _maxPlayers,
          fieldId: _selectedFieldId,
          description: _descCtrl.text.trim().isEmpty
              ? null
              : _descCtrl.text.trim(),
        );
    if (!mounted) return;
    if (created != null) {
      ref.invalidate(openGameListProvider);
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível criar a pelada.')),
      );
    }
  }

  Future<void> _submitRecurring() async {
    final dates = _nextOccurrences(_recurringDayOfWeek, _recurringWeeks);
    var created = 0;
    for (final date in dates) {
      final dt = DateTime(date.year, date.month, date.day, _time.hour, _time.minute);
      final scheduledAt = dt.toUtc().toIso8601String();
      final result = await ref.read(createOpenGameProvider.notifier).create(
            title: _titleCtrl.text.trim(),
            sport: _sport,
            scheduledAt: scheduledAt,
            durationMinutes: _duration,
            minPlayers: _minPlayers,
            maxPlayers: _maxPlayers,
            fieldId: _selectedFieldId,
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
          );
      if (result != null) created++;
    }
    if (!mounted) return;
    ref.invalidate(openGameListProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$created peladas recorrentes criadas!')),
    );
    context.pop();
  }

  List<DateTime> _nextOccurrences(int weekday, int weeks) {
    final result = <DateTime>[];
    var dt = DateTime.now();
    while (dt.weekday != weekday) {
      dt = dt.add(const Duration(days: 1));
    }
    for (var i = 0; i < weeks; i++) {
      result.add(dt);
      dt = dt.add(const Duration(days: 7));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(createOpenGameProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.primaryVertical),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(PhosphorIcons.arrowLeft(),
                          color: AppColors.textOnPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Criar Pelada',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Título *', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Pelada de terça',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Modalidade', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'futsal', label: Text('Futsal')),
                      ButtonSegment(value: 'society', label: Text('Society')),
                      ButtonSegment(value: 'campo', label: Text('Campo')),
                    ],
                    selected: {_sport},
                    onSelectionChanged: (s) =>
                        setState(() => _sport = s.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Data e hora', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(PhosphorIcons.calendar()),
                          label: Text(
                            '${_scheduledAt.day.toString().padLeft(2, '0')}/${_scheduledAt.month.toString().padLeft(2, '0')}/${_scheduledAt.year}',
                          ),
                          onPressed: _pickDate,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(PhosphorIcons.clock()),
                          label: Text(_time.format(context)),
                          onPressed: _pickTime,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Recorrente', style: AppTextStyles.labelMedium),
                    subtitle: const Text('Criar nas próximas semanas'),
                    value: _isRecurring,
                    onChanged: (v) => setState(() => _isRecurring = v),
                  ),
                  if (_isRecurring) ...[
                    Wrap(
                      spacing: AppSpacing.xs,
                      children: List.generate(7, (i) {
                        final dayNum = i + 1;
                        return ChoiceChip(
                          label: Text(_weekDayLabels[i]),
                          selected: _recurringDayOfWeek == dayNum,
                          onSelected: (_) =>
                              setState(() => _recurringDayOfWeek = dayNum),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        const Text('Repetir por ', style: AppTextStyles.bodyMedium),
                        DropdownButton<int>(
                          value: _recurringWeeks,
                          items: [4, 8, 12]
                              .map((w) => DropdownMenuItem(
                                    value: w,
                                    child: Text('$w semanas'),
                                  ))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _recurringWeeks = v ?? 4),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  const Text('Duração (minutos)',
                      style: AppTextStyles.labelMedium),
                  Slider(
                    value: _duration.toDouble(),
                    min: 30,
                    max: 180,
                    divisions: 5,
                    label: '$_duration min',
                    onChanged: (v) => setState(() => _duration = v.round()),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Mín. jogadores',
                                style: AppTextStyles.labelMedium),
                            Slider(
                              value: _minPlayers.toDouble(),
                              min: 2,
                              max: 20,
                              divisions: 18,
                              label: '$_minPlayers',
                              onChanged: (v) =>
                                  setState(() => _minPlayers = v.round()),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Máx. jogadores',
                                style: AppTextStyles.labelMedium),
                            Slider(
                              value: _maxPlayers.toDouble(),
                              min: 4,
                              max: 30,
                              divisions: 26,
                              label: '$_maxPlayers',
                              onChanged: (v) =>
                                  setState(() => _maxPlayers = v.round()),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Campo (opcional)', style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  if (_selectedFieldId == null)
                    OutlinedButton.icon(
                      icon: Icon(PhosphorIcons.mapPin()),
                      label: const Text('Selecionar campo'),
                      onPressed: _pickField,
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedFieldName ?? '',
                                style: AppTextStyles.bodyMedium,
                              ),
                              Text(
                                _selectedFieldAddress ?? '',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(PhosphorIcons.x(), color: AppColors.textSecondary),
                          onPressed: () => setState(() {
                            _selectedFieldId = null;
                            _selectedFieldName = null;
                            _selectedFieldAddress = null;
                          }),
                        ),
                      ],
                    ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('Descrição (opcional)',
                      style: AppTextStyles.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  TextField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Informe detalhes da pelada...',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton.primary(
                    label: isLoading ? 'Criando...' : 'Criar pelada',
                    icon: PhosphorIcons.soccerBall(),
                    onPressed: isLoading ? () {} : _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
