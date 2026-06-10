import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/field/data/repositories/field_repository_provider.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldDetail {
  final Field field;
  final List<FieldCourt> courts;
  final List<PricingRule> pricingRules;

  const FieldDetail({
    required this.field,
    required this.courts,
    required this.pricingRules,
  });

  double get lowestPrice => pricingRules.isEmpty
      ? 0
      : pricingRules.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  List<FieldCourt> get activeCourts =>
      courts.where((c) => c.isActive).toList();
}


class FieldListVM extends AsyncNotifier<List<Field>> {
  @override
  Future<List<Field>> build() =>
      ref.watch(fieldRepositoryProvider).getFields();
}

final fieldListProvider =
    AsyncNotifierProvider<FieldListVM, List<Field>>(FieldListVM.new);


final fieldDetailProvider = FutureProvider.family<FieldDetail, String>(
  (ref, id) async {
    final repo = ref.read(fieldRepositoryProvider);
    final results = await Future.wait([
      repo.getFieldById(id),
      repo.getCourtsByField(id),
      repo.getPricingRules(id),
    ]);
    return FieldDetail(
      field: results[0] as Field,
      courts: results[1] as List<FieldCourt>,
      pricingRules: results[2] as List<PricingRule>,
    );
  },
);
