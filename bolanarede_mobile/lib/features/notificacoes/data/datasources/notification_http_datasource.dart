import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/notificacoes/data/models/notification_model.dart';
import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';
import 'package:bola_na_rede/features/notificacoes/domain/repositories/notification_repository.dart';

class NotificationHttpDatasource implements NotificationRepository {
  const NotificationHttpDatasource({required this.dio});

  final Dio dio;

  @override
  Future<List<AppNotification>> getNotifications({
    int skip = 0,
    int limit = 20,
  }) async {
    final response = await dio.get<List<dynamic>>(
      '/v1/notifications',
      queryParameters: <String, dynamic>{'skip': skip, 'limit': limit},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .map((m) => m.toEntity())
        .toList();
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await dio
        .get<Map<String, dynamic>>('/v1/notifications/unread-count');
    return response.data!['count'] as int;
  }

  @override
  Future<void> markAllAsRead() async {
    await dio.patch<void>('/v1/notifications/read');
  }

  @override
  Future<AppNotification> markAsRead(String id) async {
    final response = await dio
        .patch<Map<String, dynamic>>('/v1/notifications/$id/read');
    return NotificationModel.fromJson(response.data!).toEntity();
  }
}
