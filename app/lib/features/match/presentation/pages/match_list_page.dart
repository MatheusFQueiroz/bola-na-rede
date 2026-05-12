// lib/features/match/presentation/pages/match_list_page.dart

import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/themes/app_tokens.dart';
import '../../../../shared/widgets/app_components.dart';
import '../../../../core/routes/app_routes.dart';

class MatchListPage extends StatelessWidget {
  const MatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(children: [
        _buildHeader(context),
        Expanded(child: _buildEmpty()),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.createMatch),
        backgroundColor: AppColors.primary,
        icon: Icon(PhosphorIcons.plus(), color: AppColors.textOnPrimary),
        label: const Text('Nova Partida',
            style: TextStyle(color: AppColors.textOnPrimary)),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 2,
        onTap: (i) {
          if (i == 0) Navigator.pushNamed(context, AppRoutes.home);
          if (i == 1) Navigator.pushNamed(context, AppRoutes.search);
          if (i == 3) Navigator.pushNamed(context, AppRoutes.ranking);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profile);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(children: [
            const Expanded(
              child: Text('Partidas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w600)),
            ),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, AppRoutes.createMatch),
              child: Icon(PhosphorIcons.plus(),
                  color: AppColors.textOnPrimary, size: AppSizes.iconLg),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(PhosphorIcons.soccerBall(),
            size: 64, color: AppColors.textDisabled),
        const SizedBox(height: AppSpacing.lg),
        const Text('Nenhuma partida ainda', style: AppTextStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Text('Crie sua primeira partida',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary)),
      ]),
    );
  }
}


