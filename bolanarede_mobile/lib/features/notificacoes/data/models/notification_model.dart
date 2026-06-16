import 'package:bola_na_rede/features/notificacoes/domain/entities/notification.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        recipientUserId: json['recipientUserId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        data: (json['data'] as Map<String, dynamic>?) ?? <String, dynamic>{},
        isRead: json['isRead'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final String id;
  final String recipientUserId;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification toEntity() => AppNotification(
        id: id,
        recipientUserId: recipientUserId,
        type: type,
        title: title,
        body: body,
        data: data,
        isRead: isRead,
        createdAt: createdAt,
      );
}
