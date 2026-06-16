import 'package:json_annotation/json_annotation.dart';

import 'package:bola_na_rede/core/shared/snapshots.dart';

part 'recurring_plan.g.dart';

// RecurringPlan ⭐ Diferencial
// Tabela: field-service → recurring_plans
// Planos de horário fixo semanal — vinculados a grupo de pelada ou time

enum RecurringPlanStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('CANCELLED')
  cancelled,
}

enum LinkedEntityType {
  @JsonValue('open_game_group')
  openGameGroup,
  @JsonValue('team')
  team,
}

@JsonSerializable()
class RecurringPlan {
  const RecurringPlan({
    required this.id,
    required this.fieldId,
    required this.ownerUserId,
    required this.ownerSnapshot,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.pricePerSlot,
    required this.platformFeePct,
    required this.releaseBeforeH,
    required this.status,
    required this.validFrom,
    required this.createdAt,
    required this.updatedAt,
    this.courtId,
    this.linkedEntityType,
    this.linkedEntityId,
    this.validUntil,
  });

  factory RecurringPlan.fromJson(Map<String, dynamic> json) =>
      _$RecurringPlanFromJson(json);

  /// = recurring_plans.external_id (UUID)
  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  @JsonKey(name: 'court_id')
  final String? courtId;

  /// = users.external_id do capitão/organizador responsável
  @JsonKey(name: 'owner_user_id')
  final String ownerUserId;

  @JsonKey(name: 'owner_snapshot')
  final OrganizerSnapshot ownerSnapshot;

  @JsonKey(name: 'linked_entity_type')
  final LinkedEntityType? linkedEntityType;

  /// external_id do grupo ou time vinculado
  @JsonKey(name: 'linked_entity_id')
  final String? linkedEntityId;

  /// 0 = domingo … 6 = sábado
  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  @JsonKey(name: 'start_time')
  final String startTime; // HH:mm

  @JsonKey(name: 'end_time')
  final String endTime; // HH:mm

  @JsonKey(name: 'price_per_slot')
  final double pricePerSlot;

  /// % de comissão BolaNaRede (padrão 6% para planos recorrentes)
  @JsonKey(name: 'platform_fee_pct')
  final double platformFeePct;

  /// Horas antes que o slot é liberado se não houver jogo confirmado
  @JsonKey(name: 'release_before_h')
  final int releaseBeforeH;

  final RecurringPlanStatus status;

  @JsonKey(name: 'valid_from')
  final DateTime validFrom;

  /// null = indefinido
  @JsonKey(name: 'valid_until')
  final DateTime? validUntil;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$RecurringPlanToJson(this);
}

// Tabela: field-service → recurring_plan_slots
// Instância semanal de um plano recorrente

enum PlanSlotStatus {
  @JsonValue('PRE_RESERVED')
  preReserved,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('RELEASED')
  released,
  @JsonValue('CANCELLED')
  cancelled,
}

@JsonSerializable()
class RecurringPlanSlot {
  const RecurringPlanSlot({
    required this.id,
    required this.planId,
    required this.slotDate,
    required this.status,
    required this.releaseAt,
    required this.createdAt,
    this.reservationId,
    this.gameRefId,
    this.confirmedAt,
    this.releasedAt,
  });

  factory RecurringPlanSlot.fromJson(Map<String, dynamic> json) =>
      _$RecurringPlanSlotFromJson(json);

  final String id;

  @JsonKey(name: 'plan_id')
  final String planId;

  @JsonKey(name: 'slot_date')
  final DateTime slotDate;

  final PlanSlotStatus status;

  @JsonKey(name: 'reservation_id')
  final String? reservationId;

  /// external_id do open_game ou match confirmado
  @JsonKey(name: 'game_ref_id')
  final String? gameRefId;

  /// Quando o slot será liberado automaticamente se não confirmado
  @JsonKey(name: 'release_at')
  final DateTime releaseAt;

  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;

  @JsonKey(name: 'released_at')
  final DateTime? releasedAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  Map<String, dynamic> toJson() => _$RecurringPlanSlotToJson(this);
}
