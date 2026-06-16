import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/notificacoes/data/datasources/notification_datasource_provider.dart';
import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';

class NotificationViewModel
    extends AsyncNotifier<List<AppNotification>> {
  @override
  Future<List<AppNotification>> build() =>
      ref.watch(notificationRepositoryProvider).getNotifications();

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    ref.invalidateSelf();
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    ref.invalidateSelf();
  }
}

final notificationViewModelProvider =
    AsyncNotifierProvider<NotificationViewModel, List<AppNotification>>(
  NotificationViewModel.new,
);

final unreadCountProvider = FutureProvider<int>(
  (ref) => ref.watch(notificationRepositoryProvider).getUnreadCount(),
);
