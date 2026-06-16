import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:bola_na_rede/core/themes/app_tokens.dart';
import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';
import 'package:bola_na_rede/features/notificacoes/presentation/viewmodels/notification_viewmodel.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Container(
            decoration:
                const BoxDecoration(gradient: AppGradients.primaryVertical),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(PhosphorIcons.arrowLeft(),
                          color: AppColors.textOnPrimary),
                      onPressed: () => context.pop(),
                    ),
                    const Expanded(
                      child: Text(
                        'Notificações',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textOnPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    notificationsAsync.whenOrNull(
                          data: (ns) => ns.any((n) => !n.isRead)
                              ? TextButton(
                                  onPressed: () => ref
                                      .read(notificationViewModelProvider
                                          .notifier)
                                      .markAllAsRead(),
                                  child: const Text(
                                    'Marcar todas',
                                    style:
                                        TextStyle(color: AppColors.textOnPrimary),
                                  ),
                                )
                              : const SizedBox(width: 48),
                        ) ??
                        const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: notificationsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  'Não foi possível carregar as notificações.',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ),
              ),
              data: (notifications) => notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIcons.bellSlash(),
                              size: 48, color: AppColors.textDisabled),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Nenhuma notificação',
                            style: AppTextStyles.titleMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1),
                      itemBuilder: (_, i) =>
                          _notificationTile(context, ref, notifications[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _notificationTile(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return ListTile(
      tileColor: notification.isRead ? null : AppColors.primarySurface,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: notification.isRead
              ? AppColors.surface
              : AppColors.primarySurface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          _iconForType(notification.type),
          color: AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        notification.title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight:
              notification.isRead ? FontWeight.w400 : FontWeight.w700,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          Text(
            _formatDate(notification.createdAt),
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textDisabled),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: notification.isRead
          ? null
          : () => ref
              .read(notificationViewModelProvider.notifier)
              .markAsRead(notification.id),
    );
  }

  IconData _iconForType(String type) => switch (type) {
        'match_accepted' || 'match_confirmed' => PhosphorIcons.calendar(),
        'match_result' || 'result_confirmed' => PhosphorIcons.trophy(),
        'team_invite' || 'team_joined' => PhosphorIcons.users(),
        'new_review' => PhosphorIcons.star(),
        'open_game_joined' => PhosphorIcons.soccerBall(),
        _ => PhosphorIcons.bell(),
      };

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inHours < 1) return 'Há ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Há ${diff.inHours}h';
    if (diff.inDays < 7) return 'Há ${diff.inDays} dia(s)';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }
}
