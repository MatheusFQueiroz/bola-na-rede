import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';

abstract class NotificationRepository {
  Future<List<AppNotification>> getNotifications({int skip, int limit});
  Future<int> getUnreadCount();
  Future<void> markAllAsRead();
  Future<AppNotification> markAsRead(String id);
}
