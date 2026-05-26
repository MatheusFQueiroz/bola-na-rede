import 'package:flutter/material.dart';
import '../../domain/entities/field.dart';
import '../../domain/repositories/field_repository.dart';

enum FieldViewState { idle, loading, success, error }

class FieldViewModel extends ChangeNotifier {
  final FieldRepository repository;

  FieldViewModel({required this.repository});

  // — Lista de campos
  FieldViewState _listState = FieldViewState.idle;
  List<Field> _fields = [];
  String? _listError;

  FieldViewState get listState => _listState;
  List<Field> get fields => _fields;
  String? get listError => _listError;

  // — Detalhe do campo
  FieldViewState _detailState = FieldViewState.idle;
  Field? _selectedField;
  List<FieldCourt> _courts = [];
  List<PricingRule> _pricingRules = [];
  String? _detailError;

  FieldViewState get detailState => _detailState;
  Field? get selectedField => _selectedField;
  List<FieldCourt> get courts => _courts;
  List<PricingRule> get pricingRules => _pricingRules;
  String? get detailError => _detailError;

  Future<void> loadFields() async {
    _listState = FieldViewState.loading;
    _listError = null;
    notifyListeners();

    try {
      _fields = await repository.getFields();
      _listState = FieldViewState.success;
    } catch (e) {
      _listError = 'Não foi possível carregar os campos.';
      _listState = FieldViewState.error;
    }
    notifyListeners();
  }

  Future<void> loadFieldDetail(String fieldId) async {
    _detailState = FieldViewState.loading;
    _detailError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        repository.getFieldById(fieldId),
        repository.getCourtsByField(fieldId),
        repository.getPricingRules(fieldId),
      ]);
      _selectedField = results[0] as Field;
      _courts = results[1] as List<FieldCourt>;
      _pricingRules = results[2] as List<PricingRule>;
      _detailState = FieldViewState.success;
    } catch (e) {
      _detailError = 'Não foi possível carregar o campo.';
      _detailState = FieldViewState.error;
    }
    notifyListeners();
  }

  // Helpers úteis para a UI
  double get lowestPrice => _pricingRules.isEmpty
      ? 0
      : _pricingRules.map((r) => r.price).reduce((a, b) => a < b ? a : b);

  List<FieldCourt> get activeCourts =>
      _courts.where((c) => c.isActive).toList();
}
