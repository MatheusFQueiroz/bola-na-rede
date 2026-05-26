import '../../domain/entities/field.dart';
import '../../domain/repositories/field_repository.dart';
import '../datasources/field_mock_datasource.dart';

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
