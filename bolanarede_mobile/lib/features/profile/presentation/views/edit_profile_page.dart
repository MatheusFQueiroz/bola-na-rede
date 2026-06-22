import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';
import 'package:bola_na_rede/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _bioCtrl;

  PlayerPosition? _position;
  int _skillLevel = 3;
  bool _submitting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initFromProfile(PlayerProfile profile) {
    if (_initialized) return;
    _initialized = true;
    _nameCtrl.text = profile.displayName;
    _cityCtrl.text = profile.city ?? '';
    _bioCtrl.text = profile.bio ?? '';
    _position = profile.position;
    _skillLevel = _skillLevelInt(profile.skillLevel) ?? 3;
  }

  int? _skillLevelInt(SkillLevel? level) => switch (level) {
        SkillLevel.beginner => 1,
        SkillLevel.recreational => 2,
        SkillLevel.intermediate => 3,
        SkillLevel.advanced => 4,
        SkillLevel.competitive => 5,
        null => null,
      };

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);

    try {
      final input = UpdateProfileInput(
        displayName: _nameCtrl.text.trim(),
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        bio: _bioCtrl.text.trim().isEmpty ? null : _bioCtrl.text.trim(),
        position: _position,
        skillLevel: _skillLevel,
      );

      await ref.read(profileProvider.notifier).updateProfile(input);

      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    } on Exception catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao atualizar perfil. Tente novamente.')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppGradientAppBar(
        title: 'Editar perfil',
        showBackButton: true,
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: const Text(
              'Salvar',
              style: TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(
            'Não foi possível carregar o perfil.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        data: (data) {
          _initFromProfile(data.profile);
          return _buildForm(context);
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppInput(
              label: 'Nome',
              hint: 'Seu nome de jogador',
              prefixIcon: PhosphorIcons.user(),
              controller: _nameCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInput(
              label: 'Cidade',
              hint: 'Ex: Curitiba',
              prefixIcon: PhosphorIcons.mapPin(),
              controller: _cityCtrl,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppInput(
              label: 'Bio',
              hint: 'Conte um pouco sobre você',
              controller: _bioCtrl,
              maxLines: 3,
              maxLength: 200,
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildPositionDropdown(),
            const SizedBox(height: AppSpacing.lg),
            _buildSkillSlider(),
            const SizedBox(height: AppSpacing.xxxl),
            AppButton.primary(
              label: 'Salvar alterações',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Posição', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<PlayerPosition>(
          value: _position,
          decoration: InputDecoration(
            hintText: 'Selecione sua posição',
            prefixIcon: Icon(
              PhosphorIcons.soccerBall(),
              size: AppSizes.iconMd,
              color: AppColors.textSecondary,
            ),
          ),
          items: const [
            DropdownMenuItem(
              value: PlayerPosition.forward,
              child: Text('Atacante'),
            ),
            DropdownMenuItem(
              value: PlayerPosition.midfielder,
              child: Text('Meia'),
            ),
            DropdownMenuItem(
              value: PlayerPosition.defender,
              child: Text('Zagueiro'),
            ),
            DropdownMenuItem(
              value: PlayerPosition.goalkeeper,
              child: Text('Goleiro'),
            ),
          ],
          onChanged: (v) => setState(() => _position = v),
        ),
      ],
    );
  }

  Widget _buildSkillSlider() {
    final labels = ['Iniciante', 'Recreativo', 'Intermediário', 'Avançado', 'Competitivo'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Nível de habilidade', style: AppTextStyles.labelMedium),
        const SizedBox(height: AppSpacing.xs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${labels[_skillLevel - 1]} ($_skillLevel)',
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            inactiveTrackColor: AppColors.primaryBorder,
            overlayColor: AppColors.primary.withValues(alpha: 0.15),
          ),
          child: Slider(
            value: _skillLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _skillLevel = v.round()),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text('1', style: AppTextStyles.labelSmall),
            Text('5', style: AppTextStyles.labelSmall),
          ],
        ),
      ],
    );
  }
}
