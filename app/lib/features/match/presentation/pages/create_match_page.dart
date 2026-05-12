import 'package:flutter/material.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_components.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CreateMatchPage extends StatefulWidget {
  const CreateMatchPage({super.key});
  @override
  State<CreateMatchPage> createState() => _CreateMatchPageState();
}

class _CreateMatchPageState extends State<CreateMatchPage> {
  String _type = 'Pelada';
  String _modality = 'Society';
  String _access = 'Aberto';
  int _slots = 14;
  bool _recurring = false;
  final _modalities = ['Society', 'Futsal', 'Campo', 'Peladona'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(title: 'Nova Partida', showBackButton: true),
      body: Stack(children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('Tipo de partida'),
            Row(children: [
              Expanded(child: _typeCard('Desafio', 'Desafie outro time', PhosphorIcons.shield())),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _typeCard('Pelada', 'Partida aberta para jogadores', PhosphorIcons.soccerBall())),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Titulo da partida'),
            const AppInput(
              label: '',
              hint: 'Ex: Pelada da Quinta — Vila Madeleine',
              maxLength: 50,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Modalidade'),
            Wrap(
              spacing: AppSpacing.sm,
              children: _modalities.map((m) => AppFilterChip(
                label: m,
                selected: _modality == m,
                onTap: () => setState(() => _modality = m),
              )).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Data'),
            AppInput(
              label: '',
              hint: 'DD/MM/AAAA',
              prefixIcon: PhosphorIcons.calendar(),
              keyboardType: TextInputType.datetime,
            ),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Horario'),
            Row(children: [
              const Expanded(child: AppInput(label: 'Inicio', hint: '19:00')),
              const SizedBox(width: AppSpacing.md),
              const Expanded(child: AppInput(label: 'Termino', hint: '21:00')),
            ]),
            const SizedBox(height: AppSpacing.xl),
            _sectionLabel('Local / Campo'),
            AppInput(
              label: '',
              hint: 'Nome do campo ou endereco',
              prefixIcon: PhosphorIcons.mapPin(),
            ),
            Text('Digite o nome do campo onde sera a partida',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            if (_type == 'Pelada') ...[
              const SizedBox(height: AppSpacing.xl),
              _sectionLabel('Vagas disponiveis'),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _counterBtn(PhosphorIcons.minus(), () => setState(() { if (_slots > 2) _slots--; }), false),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Text('$_slots',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ),
                _counterBtn(PhosphorIcons.plus(), () => setState(() => _slots++), true),
              ]),
              Text('Inclua jogadores dos dois lados',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),
              _sectionLabel('Tipo de acesso'),
              _accessCard('Aberto', 'Qualquer jogador pode entrar', PhosphorIcons.lockOpen()),
              const SizedBox(height: AppSpacing.sm),
              _accessCard('Fechado', 'Somente jogadores convidados', PhosphorIcons.lock()),
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
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(color: AppColors.surface, boxShadow: AppShadows.modal),
            child: AppButton.primary(
              label: 'Criar Partida',
              onPressed: () => Navigator.pushNamed(context, AppRoutes.matchDetail),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
    child: Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
  );

  Widget _typeCard(String type, String subtitle, IconData icon) {
    final selected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: selected ? AppColors.primarySurface : AppColors.surface,
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
          borderRadius: AppRadius.cardRadius,
        ),
        child: Stack(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary, size: AppSizes.iconLg),
            const SizedBox(height: AppSpacing.sm),
            Text(type, style: AppTextStyles.titleSmall.copyWith(color: selected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ]),
          if (selected)
            Positioned(
              top: 0, right: 0,
              child: Icon(PhosphorIcons.checkCircle(), color: AppColors.primary, size: AppSizes.iconMd),
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
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(children: [
          Icon(icon, color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type, style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.primary : AppColors.textPrimary)),
            Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ])),
              Icon(selected ? PhosphorIcons.radioButton(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
              color: selected ? AppColors.primary : AppColors.textDisabled),
        ]),
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap, bool filled) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: filled ? AppColors.primary : AppColors.surface,
          border: Border.all(color: filled ? AppColors.primary : AppColors.border),
          shape: BoxShape.circle,
        ),
        child: Icon(icon,
            color: filled ? AppColors.textOnPrimary : AppColors.textPrimary,
            size: AppSizes.iconMd),
      ),
    );
  }
}
