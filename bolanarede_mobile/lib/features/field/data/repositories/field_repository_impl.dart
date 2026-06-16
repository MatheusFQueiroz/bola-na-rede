import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';

class FieldRepositoryImpl implements FieldRepository {
  const FieldRepositoryImpl({required this.dataSource});

  final FieldDataSource dataSource;

  @override
  Future<List<Field>> getFields({String? city}) =>
      dataSource.getFields(city: city);

  @override
  Future<Field> getFieldById(String id) => dataSource.getFieldById(id);

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) =>
      dataSource.getCourtsByField(fieldId);

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) =>
      dataSource.getPricingRules(fieldId);

  @override
  Future<List<AvailabilitySlot>> getAvailability(
    String fieldId,
    DateTime date,
  ) =>
      dataSource.getAvailability(fieldId, date);
}
