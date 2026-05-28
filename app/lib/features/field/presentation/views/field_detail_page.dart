import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class FieldDetailPage extends StatefulWidget {
  const FieldDetailPage({super.key});
  @override
  State<FieldDetailPage> createState() => _FieldDetailPageState();
}

class _FieldDetailPageState extends State<FieldDetailPage> {
  int _selectedDay = 0;
  final _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        CustomScrollView(slivers: [
          // Hero foto
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(),
                const SizedBox(height: AppSpacing.md),
                _buildScheduleCard(),
                const SizedBox(height: AppSpacing.md),
                _buildCourtsCard(),
                const SizedBox(height: AppSpacing.md),
                _buildReviewsCard(),
                const SizedBox(height: AppSpacing.md),
                const AppWarningBanner(
                  message: 'Reserve com antecedencia — horarios noturnos lotam rapido!',
                ),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ]),
        // Footer fixo
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildFooter(context),
        ),
      ]),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(children: [
      Container(
        height: 260,
        color: AppColors.primarySurface,
        child: const Center(
          child: Icon(Icons.sports_soccer, size: 80, color: AppColors.primaryBorder),
        ),
      ),
      // Dots
      Positioned(
        bottom: AppSpacing.md, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(true), _dot(false), _dot(false),
        ]),
      ),
      // Botões topo
      Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.sm,
        child: _circleButton(
          Icons.arrow_back,
          () => context.pop(),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        right: AppSpacing.sm,
        child: _circleButton(Icons.favorite_border, () {}),
      ),
      // Badge disponivel
      Positioned(
        bottom: AppSpacing.xl,
        left: AppSpacing.md,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: const Text('DISPONIVEL',
              style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ),
      ),
    ]);
  }

  Widget _dot(bool active) => Container(
        width: active ? 20 : 6,
        height: 6,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active ? AppColors.textOnPrimary : Colors.white54,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      );

  Widget _circleButton(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
        ),
      );

  Widget _buildInfoCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Arena Society Xaxim', style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          const Icon(Icons.star, color: AppColors.warningIcon, size: 16),
          Text(' 4.7  38 reservas',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.primary),
          Expanded(
            child: Text(' Rua das Araucarias, 450 — Xaxim, Curitiba',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          const Icon(Icons.phone_outlined, size: 16, color: AppColors.primary),
          Text(' (41) 99999-1234',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const Divider(height: AppSpacing.xl),
        Wrap(
          spacing: AppSpacing.xs,
          children: ['Society', 'Futsal'].map((m) =>
              AppFilterChip(label: m, selected: false, onTap: () {})).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          const Icon(Icons.people_outline, size: 16, color: AppColors.primary),
          Text(' Ate 14 jogadores por time',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          const Icon(Icons.grass_outlined, size: 16, color: AppColors.primary),
          Text(' Grama sintetica',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildScheduleCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Horarios e Precos', style: AppTextStyles.titleSmall),
          const Spacer(),
          Text('Hoje, seg 07/05',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.md),
        // Chips dias
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => AppFilterChip(
              label: _days[i],
              selected: _selectedDay == i,
              onTap: () => setState(() => _selectedDay = i),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _slotRow('08:00 – 09:00', 'R\$ 90/h', true),
        const Divider(),
        _slotRow('09:00 – 10:00', 'R\$ 90/h', false),
        const Divider(),
        _slotRow('19:00 – 20:00', 'R\$ 120/h', true),
      ]),
    );
  }

  Widget _slotRow(String time, String price, bool available) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(children: [
        Text(time, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: AppSpacing.md),
        Text(price, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: available ? AppColors.primarySurface : AppColors.errorSurface,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            available ? 'DISPONIVEL' : 'LOTADO',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: available ? AppColors.primary : AppColors.error,
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCourtsCard() {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quadras disponiveis', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        _courtItem('Quadra 1 — Society', ['14 jogadores', 'Grama sintetica']),
        const SizedBox(height: AppSpacing.sm),
        _courtItem('Quadra 2 — Futsal', ['10 jogadores', 'Piso emborrachado']),
      ]),
    );
  }

  Widget _courtItem(String name, List<String> tags) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: tags.map((t) =>
              AppFilterChip(label: t, selected: false, onTap: () {})).toList(),
        ),
      ]),
    );
  }

  Widget _buildReviewsCard() {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Avaliacoes', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () {}, child: const Text('Ver todas')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        const Text('4.7', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
            const Icon(Icons.star, color: AppColors.warningIcon, size: 20))),
        Text('Baseado em 38 avaliacoes',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: AppSpacing.md),
        _reviewItem('JS', AppColors.avatarBlue, 'Joao S.', 5, 'ha 2 dias', 'Campo excelente, grama bem cuidada!'),
        const SizedBox(height: AppSpacing.sm),
        _reviewItem('PM', AppColors.avatarGreen, 'Pedro M.', 4, 'ha 5 dias', 'Estrutura boa, vestiarios limpos.'),
      ]),
    );
  }

  Widget _reviewItem(String initials, Color color, String name, int stars, String date, String comment) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          AppTeamAvatar(initials: initials, color: color, size: 32, fontSize: 12),
          const SizedBox(width: AppSpacing.sm),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            Row(children: [
              ...List.generate(5, (i) => Icon(
                i < stars ? Icons.star : Icons.star_border,
                size: 12, color: AppColors.warningIcon)),
              Text('  $date', style: AppTextStyles.bodySmall),
            ]),
          ]),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Text(comment, style: AppTextStyles.bodySmall.copyWith(fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.modal,
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('A partir de',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Text('R\$ 90/h',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppButton.primary(
            label: 'Reservar horario',
            onPressed: () {},
          ),
        ),
      ]),
    );
  }
}
