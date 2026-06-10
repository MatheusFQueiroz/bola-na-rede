import 'package:json_annotation/json_annotation.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/shared/snapshots.dart';

part 'recurring_plan.g.dart';

@JsonSerializable()
class RecurringPlan {
  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  @JsonKey(name: 'court_id')
  final String? courtId;

  @JsonKey(name: 'owner_user_id')
  final String ownerUserId;

  @JsonKey(name: 'owner_snapshot')
  final OrganizerSnapshot ownerSnapshot;

  @JsonKey(name: 'linked_entity_type')
  final String? linkedEntityType;

  @JsonKey(name: 'linked_entity_id')
  final String? linkedEntityId;

  @JsonKey(name: 'day_of_week')
  final int dayOfWeek;

  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  @JsonKey(name: 'price_per_slot')
  final double pricePerSlot;

  @JsonKey(name: 'platform_fee_pct')
  final double platformFeePct;

  @JsonKey(name: 'release_before_h')
  final int releaseBeforeH;

  final RecurringPlanStatus status;

  @JsonKey(name: 'valid_from')
  final DateTime validFrom;

  @JsonKey(name: 'valid_until')
  final DateTime? validUntil;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const RecurringPlan({
    required this.id,
    required this.fieldId,
    this.courtId,
    required this.ownerUserId,
    required this.ownerSnapshot,
    this.linkedEntityType,
    this.linkedEntityId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.pricePerSlot,
    required this.platformFeePct,
    required this.releaseBeforeH,
    required this.status,
    required this.validFrom,
    this.validUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringPlan.fromJson(Map<String, dynamic> json) =>
      _$RecurringPlanFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringPlanToJson(this);
}

@JsonSerializable()
class RecurringPlanSlot {
  final String id;

  @JsonKey(name: 'plan_id')
  final String planId;

  @JsonKey(name: 'slot_date')
  final DateTime slotDate;

  final PlanSlotStatus status;

  @JsonKey(name: 'reservation_id')
  final String? reservationId;

  @JsonKey(name: 'game_ref_id')
  final String? gameRefId;

  @JsonKey(name: 'release_at')
  final DateTime releaseAt;

  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;

  @JsonKey(name: 'released_at')
  final DateTime? releasedAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  const RecurringPlanSlot({
    required this.id,
    required this.planId,
    required this.slotDate,
    required this.status,
    this.reservationId,
    this.gameRefId,
    required this.releaseAt,
    this.confirmedAt,
    this.releasedAt,
    required this.createdAt,
  });

  factory RecurringPlanSlot.fromJson(Map<String, dynamic> json) =>
      _$RecurringPlanSlotFromJson(json);

  Map<String, dynamic> toJson() => _$RecurringPlanSlotToJson(this);
}
