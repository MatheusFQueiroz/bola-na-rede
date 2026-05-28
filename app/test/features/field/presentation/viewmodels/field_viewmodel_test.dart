import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/field/data/repositories/field_repository_provider.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';

class FakeFieldRepository implements FieldRepository {
  @override
  Future<List<Field>> getFields() async => [];
  @override
  Future<Field> getFieldById(String id) async => throw UnimplementedError();
  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) async =>
      throw UnimplementedError();
  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) async =>
      throw UnimplementedError();
}

void main() {
  ProviderContainer makeContainer() => ProviderContainer(
        overrides: [
          fieldRepositoryProvider.overrideWithValue(FakeFieldRepository()),
        ],
      );

  group('FieldViewModel', () {
    test('initial state is idle with empty lists', () {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(fieldViewModelProvider).listStatus, FieldLoadStatus.idle);
      expect(c.read(fieldViewModelProvider).fields, isEmpty);
    });

    test('loadFields sets listStatus to success', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      await c.read(fieldViewModelProvider.notifier).loadFields();

      expect(
          c.read(fieldViewModelProvider).listStatus, FieldLoadStatus.success);
    });
  });
}
