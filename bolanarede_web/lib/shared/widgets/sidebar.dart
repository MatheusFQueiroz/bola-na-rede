import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/routes/app_router.dart';
import 'package:bolanarede_web/core/themes/app_tokens.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;

    return Container(
      width: AppSizes.sidebarWidth,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: AppSizes.topbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: AppGradients.primaryVertical,
            ),
            child: Row(
              children: [
                Icon(
                  PhosphorIcons.soccerBall(),
                  color: AppColors.textOnPrimary,
                  size: 24,
                ),
                SizedBox(width: AppSpacing.sm),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BolaNaRede',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Field Manager',
                      style: TextStyle(
                        color: AppColors.textOnPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Menu
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              children: [
                _SidebarItem(
                  icon: PhosphorIcons.chartLineUp(),
                  label: 'Visão Geral',
                  route: AppRoutes.dashboard,
                  isActive: currentPath == AppRoutes.dashboard,
                ),
                _SidebarItem(
                  icon:                     PhosphorIcons.soccerBall(),
                  label: 'Meus Campos',
                  route: AppRoutes.fields,
                  isActive: currentPath.startsWith('/dashboard/fields'),
                ),
                _SidebarItem(
                  icon: PhosphorIcons.calendarBlank(),
                  label: 'Reservas',
                  route: AppRoutes.reservations,
                  isActive: currentPath.startsWith('/dashboard/reservations'),
                ),
                _SidebarItem(
                  icon: PhosphorIcons.arrowsClockwise(),
                  label: 'Planos Recorrentes',
                  route: AppRoutes.recurringPlans,
                  isActive: currentPath.startsWith('/dashboard/recurring'),
                ),
                _SidebarItem(
                  icon: PhosphorIcons.usersThree(),
                  label: 'Clientes',
                  route: AppRoutes.customers,
                  isActive: currentPath.startsWith('/dashboard/customers'),
                ),
                _SidebarItem(
                  icon: PhosphorIcons.chartBar(),
                  label: 'Relatórios',
                  route: AppRoutes.reports,
                  isActive: currentPath.startsWith('/dashboard/reports'),
                ),
              ],
            ),
          ),

          // Bottom
          const Divider(color: AppColors.divider),
          _SidebarItem(
            icon: PhosphorIcons.gearSix(),
            label: 'Configurações',
            route: AppRoutes.settings,
            isActive: currentPath.startsWith('/dashboard/settings'),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'JD',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'João Da Silva',
                        style: AppTextStyles.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'joao@email.com',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isActive;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      child: Material(
        color: isActive ? AppColors.primarySurface : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          onTap: () => context.go(route),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: isActive
                ? const BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: AppColors.primary,
                        width: 3,
                      ),
                    ),
                  )
                : null,
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppSizes.iconMd,
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
