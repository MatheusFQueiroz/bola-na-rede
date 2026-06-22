import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bola_na_rede/features/field/data/repositories/field_repository_provider.dart';
import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';
import 'package:bola_na_rede/features/field/presentation/viewmodels/field_viewmodel.dart';

class FakeFieldRepository implements FieldRepository {
  @override
  Future<List<Field>> getFields({String? city}) async => [];
  @override
  Future<Field> getFieldById(String id) async => throw UnimplementedError();
  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) async => [];
  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) async => [];
  @override
  Future<List<AvailabilitySlot>> getAvailability(
    String fieldId,
    DateTime date,
  ) async =>
      [];
}

ProviderContainer makeContainer() => ProviderContainer(
      overrides: [
        fieldRepositoryProvider.overrideWithValue(FakeFieldRepository()),
      ],
    );

void main() {
  group('fieldListProvider', () {
    test('starts loading then resolves to empty list', () async {
      final c = makeContainer();
      addTearDown(c.dispose);

      expect(c.read(fieldListProvider), isA<AsyncLoading<List<Field>>>());
      final fields = await c.read(fieldListProvider.future);
      expect(fields, isEmpty);
      expect(c.read(fieldListProvider), isA<AsyncData<List<Field>>>());
    });
  });
}
