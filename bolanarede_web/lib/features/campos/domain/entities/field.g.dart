// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Field _$FieldFromJson(Map<String, dynamic> json) => Field(
      id: json['id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      street: json['street'] as String?,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zip_code'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      coverPhotoUrl: json['cover_photo_url'] as String?,
      status: $enumDecode(_$FieldStatusEnumMap, json['status']),
      plan: $enumDecode(_$FieldPlanEnumMap, json['plan']),
      planExpiresAt: json['plan_expires_at'] == null
          ? null
          : DateTime.parse(json['plan_expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$FieldToJson(Field instance) => <String, dynamic>{
      'id': instance.id,
      'owner_user_id': instance.ownerUserId,
      'name': instance.name,
      'description': instance.description,
      'street': instance.street,
      'city': instance.city,
      'state': instance.state,
      'zip_code': instance.zipCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'contact_phone': instance.contactPhone,
      'contact_email': instance.contactEmail,
      'cover_photo_url': instance.coverPhotoUrl,
      'status': _$FieldStatusEnumMap[instance.status]!,
      'plan': _$FieldPlanEnumMap[instance.plan]!,
      'plan_expires_at': instance.planExpiresAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$FieldStatusEnumMap = {
  FieldStatus.active: 'ACTIVE',
  FieldStatus.inactive: 'INACTIVE',
  FieldStatus.suspended: 'SUSPENDED',
};

const _$FieldPlanEnumMap = {
  FieldPlan.basic: 'BASIC',
  FieldPlan.pro: 'PRO',
  FieldPlan.multi: 'MULTI',
};

FieldCourt _$FieldCourtFromJson(Map<String, dynamic> json) => FieldCourt(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      name: json['name'] as String,
      modality: $enumDecode(_$CourtModalityEnumMap, json['modality']),
      surface: $enumDecodeNullable(_$CourtSurfaceEnumMap, json['surface']),
      capacity: (json['capacity'] as num).toInt(),
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$FieldCourtToJson(FieldCourt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'field_id': instance.fieldId,
      'name': instance.name,
      'modality': _$CourtModalityEnumMap[instance.modality]!,
      'surface': _$CourtSurfaceEnumMap[instance.surface],
      'capacity': instance.capacity,
      'is_active': instance.isActive,
    };

const _$CourtModalityEnumMap = {
  CourtModality.society: 'society',
  CourtModality.futsal: 'futsal',
  CourtModality.salao: 'salao',
};

const _$CourtSurfaceEnumMap = {
  CourtSurface.grass: 'grass',
  CourtSurface.synthetic: 'synthetic',
  CourtSurface.concrete: 'concrete',
  CourtSurface.rubber: 'rubber',
};

PricingRule _$PricingRuleFromJson(Map<String, dynamic> json) => PricingRule(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      courtId: json['court_id'] as String?,
      name: json['name'] as String,
      dayOfWeek: (json['day_of_week'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      price: (json['price'] as num).toDouble(),
      isActive: json['is_active'] as bool,
    );

Map<String, dynamic> _$PricingRuleToJson(PricingRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'field_id': instance.fieldId,
      'court_id': instance.courtId,
      'name': instance.name,
      'day_of_week': instance.dayOfWeek,
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'price': instance.price,
      'is_active': instance.isActive,
    };
