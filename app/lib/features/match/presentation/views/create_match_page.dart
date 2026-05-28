import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/match/presentation/viewmodels/match_viewmodel.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';
import 'package:bola_na_rede/features/team/presentation/viewmodels/team_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class CreateMatchPage extends ConsumerStatefulWidget {
  const CreateMatchPage({super.key});
  @override
  ConsumerState<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends ConsumerState<CreateMatchPage> {
  String _type = 'Pelada';
  String _modality = 'Society';
  String _access = 'Aberto';
  int _slots = 14;
  bool _recurring = false;
  Team? _selectedTeam;
  final _modalities = ['Society', 'Futsal', 'Campo', 'Peladona'];

  final _titleController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeStartController = TextEditingController();
  final _timeEndController = TextEditingController();
  final _fieldController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teamViewModelProvider.notifier).loadTeams();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dateController.dispose();
    _timeStartController.dispose();
    _timeEndController.dispose();
    _fieldController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTeam == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione o time adversário')),
      );
      return;
    }
    if (_dateController.text.isEmpty ||
        _timeStartController.text.isEmpty ||
        _timeEndController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha data e horário')),
      );
      return;
    }

    DateTime? date;
    try {
      final parts = _dateController.text.split('/');
      date = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data inválida. Use DD/MM/AAAA')),
      );
      return;
    }

    final success = await ref.read(matchViewModelProvider.notifier).createMatch(
          teamBId: _selectedTeam!.id,
          teamBName: _selectedTeam!.name,
          teamBCity: _selectedTeam!.city,
          scheduledDate: date,
          timeStart: _timeStartController.text,
          timeEnd: _timeEndController.text,
          fieldId: null,
          fieldName:
              _fieldController.text.isNotEmpty ? _fieldController.text : null,
          fieldAddress: null,
        );

    if (!mounted) return;

    if (success) {
      context.go(AppRoutes.matchList);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(matchViewModelProvider).createError ?? 'Erro',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(matchViewModelProvider).createStatus ==
        MatchLoadStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Nova Partida', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('Tipo de partida'),
            Row(children: [
              Expanded(
                  child: _typeCard(
                      'Desafio', 'Desafie outro time', PhosphorIcons.shield())),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: _typeCard('Pelada', 'Partida aberta para jogadores',
                      PhosphorIcons.soccerBall())),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Titulo da partida'),
            AppInput(
              label: '',
              hint: 'Ex: Pelada da Quinta — Vila Madeleine',
              maxLength: 50,
              controller: _titleController,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Modalidade'),
            Wrap(
              spacing: AppSpacing.sm,
              children: _modalities
                  .map((m) => AppFilterChip(
                        label: m,
                        selected: _modality == m,
                        onTap: () => setState(() => _modality = m),
                      ))
                  .toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Time adversário'),
            _buildTeamButton(),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Data'),
            AppInput(
              label: '',
              hint: 'DD/MM/AAAA',
              prefixIcon: PhosphorIcons.calendar(),
              keyboardType: TextInputType.datetime,
              controller: _dateController,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Horario'),
            Row(children: [
              Expanded(
                  child: AppInput(
                label: 'Inicio',
                hint: '19:00',
                controller: _timeStartController,
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                  child: AppInput(
                label: 'Termino',
                hint: '21:00',
                controller: _timeEndController,
              )),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Local / Campo'),
            AppInput(
              label: '',
              hint: 'Nome do campo ou endereco',
              prefixIcon: PhosphorIcons.mapPin(),
              controller: _fieldController,
            ),
            Text('Digite o nome do campo onde sera a partida',
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            if (_type == 'Pelada') ...[
              const SizedBox(height: AppSpacing.xl),
              _sectionLabel('Vagas disponiveis'),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _counterBtn(
                    PhosphorIcons.minus(),
                    () => setState(() {
                          if (_slots > 2) _slots--;
                        }),
                    false),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text('$_slots',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                ),
                _counterBtn(
                    PhosphorIcons.plus(), () => setState(() => _slots++), true),
              ]),
              Text('Inclua jogadores dos dois lados',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              _sectionLabel('Tipo de acesso'),
              _accessCard('Aberto', 'Qualquer jogador pode entrar',
                  PhosphorIcons.lockOpen()),
              const SizedBox(height: AppSpacing.sm),
              _accessCard('Fechado', 'Somente jogadores convidados',
                  PhosphorIcons.lock()),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(children: [
              Checkbox(
                value: _recurring,
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _recurring = v ?? false),
              ),
              const Text('Partida recorrente?', style: AppTextStyles.bodyLarge),
            ]),
          ]),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
                color: AppColors.surface, boxShadow: AppShadows.modal),
            child: AppButton.primary(
              label: isLoading ? 'Criando...' : 'Criar Partida',
              onPressed: isLoading ? null : _submit,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildTeamButton() {
    return GestureDetector(
      onTap: () async {
        final team = await context.push<Object?>(AppRoutes.teamSearch);
        if (team != null && team is Team) {
          setState(() => _selectedTeam = team);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: _selectedTeam != null
              ? AppColors.primarySurface
              : AppColors.surface,
          border: Border.all(
            color: _selectedTeam != null ? AppColors.primary : AppColors.border,
            width: _selectedTeam != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          if (_selectedTeam != null) ...[
            AppTeamAvatar(
              initials: _selectedTeam!.name.substring(0, 2).toUpperCase(),
              color: AppColors.avatarBlue,
              size: 40,
              fontSize: 13,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedTeam!.name,
                        style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                    Text(_selectedTeam!.city,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ]),
            ),
            Icon(PhosphorIcons.checkCircle(), color: AppColors.primary),
          ] else ...[
            Icon(PhosphorIcons.users(), color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text('Selecionar time adversário',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
            ),
            Icon(PhosphorIcons.caretRight(), color: AppColors.textDisabled),
          ],
        ]),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Text(label,
            style: AppTextStyles.labelMedium
                .copyWith(color: AppColors.textSecondary)),
      );

  Widget _typeCard(String type, String subtitle, IconData icon) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon,
                color: selected ? AppColors.primary : AppColors.textSecondary,
                size: AppSizes.iconLg),
            const SizedBox(height: AppSpacing.sm),
            Text(type,
                style: AppTextStyles.titleSmall.copyWith(
                    color:
                        selected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
          ]),
          if (selected)
            Positioned(
              top: 0,
              right: 0,
              child: Icon(PhosphorIcons.checkCircle(),
                  color: AppColors.primary, size: AppSizes.iconMd),
            ),
        ]),
      ),
    );
  }

  Widget _accessCard(String type, String subtitle, IconData icon) {
    final selected = _access == type;
    return GestureDetector(
      onTap: () => setState(() => _access = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Icon(icon,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(type,
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: selected
                            ? AppColors.primary
                            : AppColors.textPrimary)),
                Text(subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ])),
          Icon(
              selected
                  ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill)
                  : PhosphorIcons.circle(),
              color: selected ? AppColors.primary : AppColors.textDisabled),
        ]),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border:
              Border.all(color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: filled ? AppColors.textOnPrimary : AppColors.textPrimary,
            size: AppSizes.iconMd),
      ),
    );
  }
}
