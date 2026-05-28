import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';
import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';

class FieldRepositoryImpl implements FieldRepository {
  final FieldDataSource dataSource;

  FieldRepositoryImpl({required this.dataSource});

  @override
  Future<List<Field>> getFields() => dataSource.getFields();

  @override
  Future<Field> getFieldById(String id) => dataSource.getFieldById(id);

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) =>
      dataSource.getCourtsByField(fieldId);

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) =>
      dataSource.getPricingRules(fieldId);
}
