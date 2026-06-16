import 'package:bola_na_rede/features/field/domain/entities/availability.dart';
import 'package:bola_na_rede/features/field/domain/entities/field.dart';

abstract class FieldDataSource {
  Future<List<Field>> getFields({String? city});
  Future<Field> getFieldById(String id);
  Future<List<FieldCourt>> getCourtsByField(String fieldId);
  Future<List<PricingRule>> getPricingRules(String fieldId);
  Future<List<AvailabilitySlot>> getAvailability(String fieldId, DateTime date);
}

class FieldMockDataSource implements FieldDataSource {
  static final _fields = [
    Field(
      id: 'field-001',
      ownerUserId: 'user-001',
      name: 'Arena Society Xaxim',
      description: 'Campo society com vestiário completo e estacionamento',
      street: 'Rua das Araucarias, 450',
      city: 'Curitiba',
      state: 'PR',
      zipCode: '81520-000',
      latitude: -25.5169,
      longitude: -49.2648,
      contactPhone: '41999991234',
      contactEmail: 'arena@xaxim.com',
      status: FieldStatus.active,
      plan: FieldPlan.pro,
      planExpiresAt: DateTime(2025, 12, 31),
      createdAt: DateTime(2024, 1, 10),
      updatedAt: DateTime(2024, 6),
    ),
    Field(
      id: 'field-002',
      ownerUserId: 'user-002',
      name: 'Campo do Ze',
      description: 'Campo society tradicional do Pinheirinho',
      street: 'Av. Pinheirinho, 200',
      city: 'Curitiba',
      state: 'PR',
      zipCode: '81980-000',
      latitude: -25.5421,
      longitude: -49.3012,
      contactPhone: '41988882222',
      status: FieldStatus.active,
      plan: FieldPlan.pro,
      planExpiresAt: DateTime(2025, 12, 31),
      createdAt: DateTime(2024, 2, 5),
      updatedAt: DateTime(2024, 6),
    ),
    Field(
      id: 'field-003',
      ownerUserId: 'user-003',
      name: 'Futsal Center Portao',
      description: 'Centro esportivo com 3 quadras de futsal e salão',
      street: 'Rua Portao, 800',
      city: 'Curitiba',
      state: 'PR',
      zipCode: '81070-000',
      latitude: -25.5301,
      longitude: -49.3198,
      contactPhone: '41977773333',
      contactEmail: 'futsal@portao.com',
      status: FieldStatus.active,
      plan: FieldPlan.multi,
      planExpiresAt: DateTime(2025, 12, 31),
      createdAt: DateTime(2024, 3),
      updatedAt: DateTime(2024, 6),
    ),
  ];

  static final _courts = {
    'field-001': [
      const FieldCourt(
        id: 'court-001a',
        fieldId: 'field-001',
        name: 'Quadra 1 — Society',
        modality: CourtModality.society,
        surface: CourtSurface.synthetic,
        capacity: 14,
        isActive: true,
      ),
      const FieldCourt(
        id: 'court-001b',
        fieldId: 'field-001',
        name: 'Quadra 2 — Futsal',
        modality: CourtModality.futsal,
        surface: CourtSurface.concrete,
        capacity: 10,
        isActive: true,
      ),
    ],
    'field-002': [
      const FieldCourt(
        id: 'court-002a',
        fieldId: 'field-002',
        name: 'Quadra Principal',
        modality: CourtModality.society,
        surface: CourtSurface.grass,
        capacity: 14,
        isActive: true,
      ),
    ],
    'field-003': [
      const FieldCourt(
        id: 'court-003a',
        fieldId: 'field-003',
        name: 'Quadra Futsal A',
        modality: CourtModality.futsal,
        surface: CourtSurface.concrete,
        capacity: 10,
        isActive: true,
      ),
      const FieldCourt(
        id: 'court-003b',
        fieldId: 'field-003',
        name: 'Quadra Futsal B',
        modality: CourtModality.futsal,
        surface: CourtSurface.concrete,
        capacity: 10,
        isActive: true,
      ),
      const FieldCourt(
        id: 'court-003c',
        fieldId: 'field-003',
        name: 'Salão',
        modality: CourtModality.salao,
        surface: CourtSurface.concrete,
        capacity: 8,
        isActive: false,
      ),
    ],
  };

  static final _pricing = {
    'field-001': [
      const PricingRule(
        id: 'price-001a',
        fieldId: 'field-001',
        name: 'Manhã',
        dayOfWeek: [1, 2, 3, 4, 5],
        startTime: '08:00',
        endTime: '12:00',
        price: 90,
        isActive: true,
      ),
      const PricingRule(
        id: 'price-001b',
        fieldId: 'field-001',
        name: 'Noturno',
        dayOfWeek: [1, 2, 3, 4, 5],
        startTime: '18:00',
        endTime: '22:00',
        price: 120,
        isActive: true,
      ),
      const PricingRule(
        id: 'price-001c',
        fieldId: 'field-001',
        name: 'Final de semana',
        dayOfWeek: [0, 6],
        startTime: '08:00',
        endTime: '22:00',
        price: 150,
        isActive: true,
      ),
    ],
    'field-002': [
      const PricingRule(
        id: 'price-002a',
        fieldId: 'field-002',
        name: 'Padrão',
        startTime: '08:00',
        endTime: '22:00',
        price: 90,
        isActive: true,
      ),
    ],
    'field-003': [
      const PricingRule(
        id: 'price-003a',
        fieldId: 'field-003',
        name: 'Padrão',
        startTime: '08:00',
        endTime: '22:00',
        price: 80,
        isActive: true,
      ),
    ],
  };

  @override
  Future<List<Field>> getFields({String? city}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (city != null && city.isNotEmpty) {
      return _fields.where((f) => f.city == city).toList();
    }
    return List.from(_fields);
  }

  @override
  Future<Field> getFieldById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _fields.firstWhere(
      (f) => f.id == id,
      orElse: () => throw Exception('Field $id não encontrado'),
    );
  }

  @override
  Future<List<FieldCourt>> getCourtsByField(String fieldId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.from(_courts[fieldId] ?? []);
  }

  @override
  Future<List<PricingRule>> getPricingRules(String fieldId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List.from(_pricing[fieldId] ?? []);
  }

  @override
  Future<List<AvailabilitySlot>> getAvailability(
    String fieldId,
    DateTime date,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return [];
  }
}
