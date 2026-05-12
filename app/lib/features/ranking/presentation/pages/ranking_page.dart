// lib/features/ranking/presentation/pages/ranking_page.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../core/routes/app_routes.dart';

class _RankItem {
  final int pos;
  final String initials;
  final Color color;
  final String name;
  final String sub;
  final String value;
  final String extra;
  const _RankItem({required this.pos, required this.initials,
      required this.color, required this.name, required this.sub,
      required this.value, required this.extra});
}

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});
  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  int _tab = 0;
  String _filter = 'Geral';
  final _filters = ['Geral', 'Sao Paulo', 'Esta semana', 'Este mes'];

  final _teams = [
    _RankItem(pos:1, initials:'UN', color:AppColors.avatarBlue, name:'Uniao Vila', sub:'46 jogos', value:'40 pts', extra:'+18'),
    _RankItem(pos:2, initials:'DZ', color:AppColors.avatarRed, name:'Dragoes da ZL', sub:'36 jogos', value:'30 pts', extra:'+10'),
    _RankItem(pos:3, initials:'FU', color:AppColors.avatarGreen, name:'Furacao FC', sub:'42 jogos', value:'20 pts', extra:'+5'),
    _RankItem(pos:4, initials:'LE', color:AppColors.avatarTeal, name:'Leoes FC', sub:'28 jogos', value:'18 pts', extra:'+12'),
    _RankItem(pos:5, initials:'RS', color:AppColors.avatarPurple, name:'Rapidos SC', sub:'19 jogos', value:'15 pts', extra:'+5'),
    _RankItem(pos:6, initials:'TR', color:AppColors.avatarOrange, name:'Trovoes', sub:'22 jogos', value:'12 pts', extra:'-3'),
    _RankItem(pos:7, initials:'ES', color:AppColors.avatarBlue, name:'Estrelas', sub:'15 jogos', value:'10 pts', extra:'-1'),
    _RankItem(pos:8, initials:'GU', color:AppColors.avatarRed, name:'Guerreiros', sub:'12 jogos', value:'6 pts', extra:'-8'),
  ];

  final _players = [
    _RankItem(pos:1, initials:'CA', color:AppColors.avatarGreen, name:'Carlos Souza', sub:'Furacao FC · Atacante', value:'28 gols', extra:'42 jogos'),
    _RankItem(pos:2, initials:'AN', color:AppColors.avatarBlue, name:'Andre Lima', sub:'Uniao Vila · Meia', value:'22 gols', extra:'38 jogos'),
    _RankItem(pos:3, initials:'MA', color:AppColors.avatarRed, name:'Marcos Rocha', sub:'Dragoes da ZL · Atacante', value:'19 gols', extra:'30 jogos'),
    _RankItem(pos:4, initials:'JO', color:AppColors.avatarTeal, name:'Joao Silva', sub:'Furacao FC · Goleiro', value:'3 gols', extra:'40 jogos'),
    _RankItem(pos:5, initials:'PE', color:AppColors.avatarPurple, name:'Pedro Alves', sub:'Furacao FC · Zagueiro', value:'5 gols', extra:'35 jogos'),
    _RankItem(pos:6, initials:'LU', color:AppColors.avatarOrange, name:'Lucas Costa', sub:'Furacao FC · Meia', value:'8 gols', extra:'32 jogos'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = _tab == 0 ? _teams : _players;
    final top3 = items.take(3).toList();
    final rest = items.skip(3).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            itemCount: _filters.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (_, i) => AppFilterChip(
              label: _filters[i],
              selected: _filter == _filters[i],
              onTap: () => setState(() => _filter = _filters[i]),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _buildPodium(top3),
              const SizedBox(height: AppSpacing.md),
              _buildList(rest),
              const SizedBox(height: AppSpacing.md),
              _buildMyCard(),
            ],
          ),
        ),
      ]),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 3,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, AppRoutes.home);
          if (i == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.matchList);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(bottom: false, child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          child: Row(children: [
            const Expanded(child: Text('Ranking', textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textOnPrimary, fontSize: 17, fontWeight: FontWeight.w600))),
            Icon(PhosphorIcons.trophy(), color: AppColors.textOnPrimary, size: AppSizes.iconLg),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              children: ['Times', 'Jogadores'].asMap().entries.map((e) {
                final active = _tab == e.key;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _tab = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: active ? AppColors.surface : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(e.value, textAlign: TextAlign.center,
                          style: TextStyle(
                            color: active ? AppColors.primary : AppColors.textOnPrimary,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                            fontSize: 14,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ])),
    );
  }

  Widget _buildPodium(List<_RankItem> top3) {
    if (top3.length < 3) return const SizedBox();
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _podiumItem(top3[1], 52),
            _podiumItem(top3[0], 72),
            _podiumItem(top3[2], 44),
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(_RankItem item, double size) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      if (item.pos == 1)
        Icon(PhosphorIcons.crown(PhosphorIconsStyle.fill),
            color: AppColors.warningIcon, size: 18),
      AppTeamAvatar(initials: item.initials, color: item.color,
          size: size, fontSize: size > 60 ? 20 : 14),
      const SizedBox(height: AppSpacing.xs),
      Text('${item.pos}', style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: item.pos == 1 ? 18 : 14,
          color: item.pos == 1 ? AppColors.warningIcon : AppColors.textSecondary)),
      SizedBox(
        width: 80,
        child: Text(item.name, style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
      ),
      Text(item.value, style: const TextStyle(
          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
    ]);
  }

  Widget _buildList(List<_RankItem> items) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Classificacao completa', style: AppTextStyles.titleSmall),
          const Spacer(),
          Text('Temporada 2025',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        ]),
        ...items.map((item) => Column(children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(children: [
              SizedBox(width: 28,
                  child: Text('#${item.pos}',
                      style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w700))),
              AppTeamAvatar(initials: item.initials, color: item.color, size: 32, fontSize: 11),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700)),
                Text(item.sub, style: AppTextStyles.bodySmall),
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(item.value, style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                Text(item.extra, style: AppTextStyles.bodySmall),
              ]),
            ]),
          ),
        ])),
      ]),
    );
  }

  Widget _buildMyCard() {
    return AppCard(
      color: AppColors.primarySurface,
      border: Border.all(color: AppColors.primary),
      child: Row(children: [
        const AppTeamAvatar(initials: 'FU', color: AppColors.avatarGreen, size: 40),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Furacao FC', style: AppTextStyles.titleSmall),
          Text(
            _tab == 0 ? 'Sua posicao: #3  20 pts' : 'Carlos Souza  #1  28 gols',
            style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600)),
        ])),
      ]),
    );
  }
}
