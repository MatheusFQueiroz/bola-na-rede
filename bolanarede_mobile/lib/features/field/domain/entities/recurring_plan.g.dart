// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringPlan _$RecurringPlanFromJson(Map<String, dynamic> json) =>
    RecurringPlan(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      courtId: json['court_id'] as String?,
      ownerUserId: json['owner_user_id'] as String,
      ownerSnapshot: OrganizerSnapshot.fromJson(
          json['owner_snapshot'] as Map<String, dynamic>),
      linkedEntityType: $enumDecodeNullable(
          _$LinkedEntityTypeEnumMap, json['linked_entity_type']),
      linkedEntityId: json['linked_entity_id'] as String?,
      dayOfWeek: (json['day_of_week'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      pricePerSlot: (json['price_per_slot'] as num).toDouble(),
      platformFeePct: (json['platform_fee_pct'] as num).toDouble(),
      releaseBeforeH: (json['release_before_h'] as num).toInt(),
      status: $enumDecode(_$RecurringPlanStatusEnumMap, json['status']),
      validFrom: DateTime.parse(json['valid_from'] as String),
      validUntil: json['valid_until'] == null
          ? null
          : DateTime.parse(json['valid_until'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$RecurringPlanToJson(RecurringPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'field_id': instance.fieldId,
      'court_id': instance.courtId,
      'owner_user_id': instance.ownerUserId,
      'owner_snapshot': instance.ownerSnapshot,
      'linked_entity_type':
          _$LinkedEntityTypeEnumMap[instance.linkedEntityType],
      'linked_entity_id': instance.linkedEntityId,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'price_per_slot': instance.pricePerSlot,
      'platform_fee_pct': instance.platformFeePct,
      'release_before_h': instance.releaseBeforeH,
      'status': _$RecurringPlanStatusEnumMap[instance.status]!,
      'valid_from': instance.validFrom.toIso8601String(),
      'valid_until': instance.validUntil?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$LinkedEntityTypeEnumMap = {
  LinkedEntityType.openGameGroup: 'open_game_group',
  LinkedEntityType.team: 'team',
};

const _$RecurringPlanStatusEnumMap = {
  RecurringPlanStatus.active: 'ACTIVE',
  RecurringPlanStatus.paused: 'PAUSED',
  RecurringPlanStatus.cancelled: 'CANCELLED',
};

RecurringPlanSlot _$RecurringPlanSlotFromJson(Map<String, dynamic> json) =>
    RecurringPlanSlot(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      slotDate: DateTime.parse(json['slot_date'] as String),
      status: $enumDecode(_$PlanSlotStatusEnumMap, json['status']),
      reservationId: json['reservation_id'] as String?,
      gameRefId: json['game_ref_id'] as String?,
      releaseAt: DateTime.parse(json['release_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      releasedAt: json['released_at'] == null
          ? null
          : DateTime.parse(json['released_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$RecurringPlanSlotToJson(RecurringPlanSlot instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan_id': instance.planId,
      'slot_date': instance.slotDate.toIso8601String(),
      'status': _$PlanSlotStatusEnumMap[instance.status]!,
      'reservation_id': instance.reservationId,
      'game_ref_id': instance.gameRefId,
      'release_at': instance.releaseAt.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'released_at': instance.releasedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
    };

const _$PlanSlotStatusEnumMap = {
  PlanSlotStatus.preReserved: 'PRE_RESERVED',
  PlanSlotStatus.confirmed: 'CONFIRMED',
  PlanSlotStatus.released: 'RELEASED',
  PlanSlotStatus.cancelled: 'CANCELLED',
};
