import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/routes/app_router.dart';
import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(authViewModelProvider, (previous, next) {
      final user = next.value;
      if (user != null && context.mounted && GoRouterState.of(context).matchedLocation == AppRoutes.splash) {
        context.go(AppRoutes.home);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primaryVertical),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Icon(PhosphorIcons.soccerBall(),
                    size: 300, color: AppColors.textOnPrimary),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: AppShadows.card,
                      ),
                      child: Icon(PhosphorIcons.soccerBall(),
                          size: 56, color: AppColors.primary),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Text('BolaNaRede',
                        style: AppTextStyles.displayLarge),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Organize suas partidas de futebol',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textOnPrimary.withValues(alpha: 0.8)),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: ElevatedButton(
                        onPressed: () =>
                            context.go(AppRoutes.login),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonRadius),
                          elevation: 0,
                          textStyle: AppTextStyles.labelLarge
                              .copyWith(color: AppColors.primary),
                        ),
                        child: const Text('Entrar',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      height: AppSizes.buttonHeight,
                      child: OutlinedButton(
                        onPressed: () =>
                            context.go(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textOnPrimary,
                          side: const BorderSide(
                              color: AppColors.textOnPrimary, width: 1.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.buttonRadius),
                        ),
                        child: const Text('Criar conta'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TextButton(
                      onPressed: () =>
                          context.go(AppRoutes.home),
                      child: Text(
                        'Continuar sem conta',
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textOnPrimary.withValues(alpha: 0.7)),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
