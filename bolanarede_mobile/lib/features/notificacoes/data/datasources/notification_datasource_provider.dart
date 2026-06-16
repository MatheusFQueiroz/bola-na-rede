import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/notificacoes/data/datasources/notification_http_datasource.dart';
import 'package:bola_na_rede/features/notificacoes/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationHttpDatasource(dio: ref.watch(dioProvider)),
);
