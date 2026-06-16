import 'package:json_annotation/json_annotation.dart';

part 'field.g.dart';

// Tabela: field-service → fields
// Nota: plano BASIC não aparece no catálogo BolaNaRede (regra de negócio)

enum FieldStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('INACTIVE')
  inactive,
  @JsonValue('SUSPENDED')
  suspended,
}

enum FieldPlan {
  @JsonValue('BASIC')
  basic,
  @JsonValue('PRO')
  pro,
  @JsonValue('MULTI')
  multi,
}

enum CourtModality {
  @JsonValue('society')
  society,
  @JsonValue('futsal')
  futsal,
  @JsonValue('salao')
  salao,
}

enum CourtSurface {
  @JsonValue('grass')
  grass,
  @JsonValue('synthetic')
  synthetic,
  @JsonValue('concrete')
  concrete,
}

@JsonSerializable()
class Field {
  const Field({
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.city,
    required this.state,
    required this.status,
    required this.plan,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.street,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.contactPhone,
    this.contactEmail,
    this.coverPhotoUrl,
    this.planExpiresAt,
  });

  factory Field.fromJson(Map<String, dynamic> json) => _$FieldFromJson(json);

  /// = fields.external_id (UUID)
  final String id;

  @JsonKey(name: 'owner_user_id')
  final String ownerUserId;

  final String name;
  final String? description;
  final String? street;
  final String city;
  final String state;

  @JsonKey(name: 'zip_code')
  final String? zipCode;

  final double? latitude;
  final double? longitude;

  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  @JsonKey(name: 'contact_email')
  final String? contactEmail;

  @JsonKey(name: 'cover_photo_url')
  final String? coverPhotoUrl;

  final FieldStatus status;
  final FieldPlan plan;

  @JsonKey(name: 'plan_expires_at')
  final DateTime? planExpiresAt;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => _$FieldToJson(this);
}

// Tabela: field-service → field_courts
// Representa cada quadra/espaço físico dentro de um campo

@JsonSerializable()
class FieldCourt {
  const FieldCourt({
    required this.id,
    required this.fieldId,
    required this.name,
    required this.modality,
    required this.capacity,
    required this.isActive,
    this.surface,
  });

  factory FieldCourt.fromJson(Map<String, dynamic> json) =>
      _$FieldCourtFromJson(json);

  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  final String name;
  final CourtModality modality;
  final CourtSurface? surface;

  /// Número de jogadores por time
  final int capacity;

  @JsonKey(name: 'is_active')
  final bool isActive;

  Map<String, dynamic> toJson() => _$FieldCourtToJson(this);
}

// Tabela: field-service → pricing_rules

@JsonSerializable()
class PricingRule {
  const PricingRule({
    required this.id,
    required this.fieldId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isActive,
    this.courtId,
    this.dayOfWeek,
  });

  factory PricingRule.fromJson(Map<String, dynamic> json) =>
      _$PricingRuleFromJson(json);

  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  @JsonKey(name: 'court_id')
  final String? courtId;

  final String name;

  /// null = todos os dias; 0 = domingo … 6 = sábado
  @JsonKey(name: 'day_of_week')
  final List<int>? dayOfWeek;

  @JsonKey(name: 'start_time')
  final String startTime; // HH:mm

  @JsonKey(name: 'end_time')
  final String endTime; // HH:mm

  final double price;

  @JsonKey(name: 'is_active')
  final bool isActive;

  Map<String, dynamic> toJson() => _$PricingRuleToJson(this);
}
