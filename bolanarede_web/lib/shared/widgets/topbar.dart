import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bolanarede_web/core/themes/app_tokens.dart';

class Topbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const Topbar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.topbarHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(title, style: AppTextStyles.titleMedium),
          const Spacer(),
          ...?actions,
          const SizedBox(width: AppSpacing.lg),
          IconButton(
            onPressed: () {},
            icon: Icon(
              PhosphorIcons.bell(),
              size: AppSizes.iconMd,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          const CircleAvatar(
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
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(AppSizes.topbarHeight);
}
