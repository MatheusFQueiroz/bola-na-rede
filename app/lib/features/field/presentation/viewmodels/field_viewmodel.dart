import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/field/data/repositories/field_repository_provider.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';

enum FieldLoadStatus { idle, loading, success, error }

class FieldState {
  final FieldLoadStatus listStatus;
  final List<Field> fields;
  final String? listError;
  final FieldLoadStatus detailStatus;
  final Field? selectedField;
  final List<FieldCourt> courts;
  final List<PricingRule> pricingRules;
  final String? detailError;

  const FieldState({
    required this.listStatus,
    required this.fields,
    this.listError,
    required this.detailStatus,
    this.selectedField,
    required this.courts,
    required this.pricingRules,
    this.detailError,
  });

  const FieldState.initial()
      : listStatus = FieldLoadStatus.idle,
        fields = const [],
        listError = null,
        detailStatus = FieldLoadStatus.idle,
        selectedField = null,
        courts = const [],
        pricingRules = const [],
        detailError = null;

  FieldState copyWith({
    FieldLoadStatus? listStatus,
    List<Field>? fields,
    String? listError,
    FieldLoadStatus? detailStatus,
    Field? selectedField,
    List<FieldCourt>? courts,
    List<PricingRule>? pricingRules,
    String? detailError,
  }) =>
      FieldState(
        listStatus: listStatus ?? this.listStatus,
        fields: fields ?? this.fields,
        listError: listError ?? this.listError,
        detailStatus: detailStatus ?? this.detailStatus,
        selectedField: selectedField ?? this.selectedField,
        courts: courts ?? this.courts,
        pricingRules: pricingRules ?? this.pricingRules,
        detailError: detailError ?? this.detailError,
      );

  double get lowestPrice => pricingRules.isEmpty
      ? 0
      : pricingRules.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  List<FieldCourt> get activeCourts => courts.where((c) => c.isActive).toList();
}

final fieldViewModelProvider =
    NotifierProvider<FieldViewModel, FieldState>(FieldViewModel.new);

class FieldViewModel extends Notifier<FieldState> {
  @override
  FieldState build() => const FieldState.initial();

  FieldRepository get _repo => ref.read(fieldRepositoryProvider);

  Future<void> loadFields() async {
    state = state.copyWith(listStatus: FieldLoadStatus.loading, listError: null);
    try {
      final fields = await _repo.getFields();
      state = state.copyWith(listStatus: FieldLoadStatus.success, fields: fields);
    } catch (_) {
      state = state.copyWith(
        listStatus: FieldLoadStatus.error,
        listError: 'Não foi possível carregar os campos.',
      );
    }
  }

  Future<void> loadFieldDetail(String fieldId) async {
    state = state.copyWith(
        detailStatus: FieldLoadStatus.loading, detailError: null);
    try {
      final results = await Future.wait([
        _repo.getFieldById(fieldId),
        _repo.getCourtsByField(fieldId),
        _repo.getPricingRules(fieldId),
      ]);
      state = state.copyWith(
        detailStatus: FieldLoadStatus.success,
        selectedField: results[0] as Field,
        courts: results[1] as List<FieldCourt>,
        pricingRules: results[2] as List<PricingRule>,
      );
    } catch (_) {
      state = state.copyWith(
        detailStatus: FieldLoadStatus.error,
        detailError: 'Não foi possível carregar o campo.',
      );
    }
  }
}
