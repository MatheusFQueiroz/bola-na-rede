import 'package:json_annotation/json_annotation.dart';

enum ReservationStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('NO_SHOW')
  noShow,
  @JsonValue('COMPLETED')
  completed,
}

enum PaymentStatus {
  @JsonValue('UNPAID')
  unpaid,
  @JsonValue('PAID')
  paid,
  @JsonValue('REFUNDED')
  refunded,
  @JsonValue('EXTERNAL')
  external,
}

enum ReservationChannel {
  @JsonValue('bolanarededb_app')
  bolanarededbApp,
  @JsonValue('manual')
  manual,
  @JsonValue('whatsapp')
  whatsapp,
  @JsonValue('phone')
  phone,
  @JsonValue('link')
  link,
}

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
  @JsonValue('rubber')
  rubber,
}

enum RecurringPlanStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('PAUSED')
  paused,
  @JsonValue('CANCELLED')
  cancelled,
}

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

enum CustomerType {
  @JsonValue('individual')
  individual,
  @JsonValue('group')
  group,
  @JsonValue('team')
  team,
}
