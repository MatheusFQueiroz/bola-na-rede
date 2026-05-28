import 'package:bola_na_rede/features/field/domain/entities/field.dart';

abstract class FieldRepository {
  Future<List<Field>> getFields();
  Future<Field> getFieldById(String id);
  Future<List<FieldCourt>> getCourtsByField(String fieldId);
  Future<List<PricingRule>> getPricingRules(String fieldId);
}
