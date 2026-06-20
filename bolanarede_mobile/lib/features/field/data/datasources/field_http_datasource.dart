import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';
import 'package:bola_na_rede/features/field/data/models/availability_model.dart';
import 'package:bola_na_rede/features/field/data/models/field_model.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldHttpDataSource implements FieldDataSource {
  const FieldHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Field>> getFields({String? city}) async {
    final response = await dio.get<Map<String, dynamic>>(
      '/v1/fields',
      queryParameters: city != null ? {'city': city} : null,
    );
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => FieldModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Field> getFieldById(String id) async {
    final response = await dio.get<Map<String, dynamic>>('/v1/fields/$id');
    return FieldModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) async {
    final response =
        await dio.get<Map<String, dynamic>>('/v1/fields/$fieldId/courts');
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map(
          (e) =>
              FieldCourtModel.fromJson(e as Map<String, dynamic>).toEntity(),
        )
        .toList();
  }

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) async => [];

  @override
  Future<List<AvailabilitySlot>> getAvailability(
    String fieldId,
    DateTime date,
  ) async {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final dateStr = '$y-$m-$d';
    final response = await dio.get<Map<String, dynamic>>(
      '/v1/fields/$fieldId/availability',
      queryParameters: {'date': dateStr},
    );
    final models = AvailabilitySlotModel.fromFieldAvailabilityJson(
      response.data!['data'] as Map<String, dynamic>,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
