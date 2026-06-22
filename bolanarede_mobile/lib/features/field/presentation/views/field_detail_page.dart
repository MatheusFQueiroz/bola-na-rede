import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';
import 'package:bola_na_rede/shared/widgets/app_components.dart';

class FieldDetailPage extends ConsumerStatefulWidget {
  const FieldDetailPage({super.key});
  @override
  ConsumerState<FieldDetailPage> createState() => _FieldDetailPageState();
}

class _FieldDetailPageState extends ConsumerState<FieldDetailPage> {
  int _selectedDay = 0;
  final _days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sab', 'Dom'];

  @override
  Widget build(BuildContext context) {
    final id = GoRouterState.of(context).pathParameters['id']!;
    return ref.watch(fieldDetailProvider(id)).when(
          data: (detail) => _buildPage(context, detail),
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => Scaffold(
            appBar: AppGradientAppBar(title: 'Campo', showBackButton: true),
            body: const Center(
                child: Text('Não foi possível carregar o campo.')),
          ),
        );
  }

  Widget _buildPage(BuildContext context, FieldDetail detail) {
    final field = detail.field;
    final address = field.street != null
        ? '${field.street}, ${field.city} — ${field.state}'
        : '${field.city} — ${field.state}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(children: [
        CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _buildHero(context)),
          SliverPadding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(field.name, address),
                const SizedBox(height: AppSpacing.md),
                if (field.latitude != null && field.longitude != null) ...[
                  _buildMapSection(field.latitude!, field.longitude!),
                  const SizedBox(height: AppSpacing.md),
                ],
                _buildCourtsCard(detail),
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
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: _buildFooter(context, detail),
        ),
      ]),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Stack(children: [
      Container(
        height: 260,
        color: AppColors.primarySurface,
        child: Center(
          child: Icon(PhosphorIcons.soccerBall(), size: 80, color: AppColors.primaryBorder),
        ),
      ),
      Positioned(
        bottom: AppSpacing.md, left: 0, right: 0,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dot(true), _dot(false), _dot(false),
        ]),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.sm,
        child: _circleButton(
          PhosphorIcons.arrowLeft(),
          () => context.pop(),
        ),
      ),
      Positioned(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        right: AppSpacing.sm,
        child: _circleButton(PhosphorIcons.heart(), () => showComingSoon(context)),
      ),
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
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: AppSizes.iconMd),
        ),
      );

  Widget _buildInfoCard(String name, String address) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: AppTextStyles.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: AppColors.warningIcon, size: 16),
          Text(' 4.7  38 reservas',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.sm),
        Row(children: [
          Icon(PhosphorIcons.mapPin(), size: 16, color: AppColors.primary),
          Expanded(
            child: Text(' $address',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          ),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          Icon(PhosphorIcons.phone(), size: 16, color: AppColors.primary),
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
          Icon(PhosphorIcons.users(), size: 16, color: AppColors.primary),
          Text(' Ate 14 jogadores por time',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        const SizedBox(height: AppSpacing.xs),
        Row(children: [
          Icon(PhosphorIcons.leaf(), size: 16, color: AppColors.primary),
          Text(' Grama sintetica',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
      ]),
    );
  }

  Widget _buildMapSection(double lat, double lng) {
    final point = LatLng(lat, lng);
    final mapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(PhosphorIcons.mapTrifold(), size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          const Text('Localização', style: AppTextStyles.titleSmall),
        ]),
        const SizedBox(height: AppSpacing.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 160,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: point,
                initialZoom: 16,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.bolanarede.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: point,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () async {
              await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
            },
            icon: Icon(PhosphorIcons.mapTrifold(), size: 16),
            label: const Text('Abrir no Google Maps'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCourtsCard(FieldDetail detail) {
    final courts = detail.activeCourts;
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Quadras disponiveis', style: AppTextStyles.titleSmall),
        const SizedBox(height: AppSpacing.md),
        if (courts.isEmpty)
          Text('Nenhuma quadra cadastrada.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))
        else
          ...courts.asMap().entries.map((e) => Padding(
            padding: EdgeInsets.only(top: e.key > 0 ? AppSpacing.sm : 0),
            child: _courtItem(e.value),
          )),
      ]),
    );
  }

  Widget _courtItem(FieldCourt court) {
    final tags = <String>[
      '${court.capacity} jogadores',
      court.modality.name,
    ];
    final priceLabel = court.pricePerHour != null
        ? 'R\$ ${court.pricePerHour!.toStringAsFixed(0)}/h'
        : null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(court.name,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              children: tags.map((t) =>
                  AppFilterChip(label: t, selected: false, onTap: () {})).toList(),
            ),
          ]),
        ),
        if (priceLabel != null)
          Text(priceLabel,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _buildReviewsCard() {
    return AppCard(
      child: Column(children: [
        Row(children: [
          const Text('Avaliacoes', style: AppTextStyles.titleSmall),
          const Spacer(),
          TextButton(onPressed: () => showComingSoon(context), child: const Text('Ver todas')),
        ]),
        const SizedBox(height: AppSpacing.sm),
        const Text('4.7', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.primary)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
            Icon(PhosphorIcons.star(PhosphorIconsStyle.fill), color: AppColors.warningIcon, size: 20))),
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
                i < stars
                    ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                    : PhosphorIcons.star(),
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

  Widget _buildFooter(BuildContext context, FieldDetail detail) {
    final prices = detail.activeCourts
        .map((c) => c.pricePerHour)
        .whereType<double>()
        .toList();
    final minPrice = prices.isEmpty ? null : prices.reduce((a, b) => a < b ? a : b);
    final priceLabel = minPrice != null
        ? 'R\$ ${minPrice.toStringAsFixed(0)}/h'
        : 'A consultar';

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
          Text(priceLabel,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: AppButton.primary(
            label: 'Reservar horario',
            onPressed: () => showComingSoon(context),
          ),
        ),
      ]),
    );
  }
}
