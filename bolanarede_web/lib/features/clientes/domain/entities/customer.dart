import 'package:json_annotation/json_annotation.dart';

import 'package:bolanarede_web/core/shared/enums.dart';

part 'customer.g.dart';

@JsonSerializable()
class FieldCustomer {
  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'contact_phone')
  final String? contactPhone;

  @JsonKey(name: 'contact_email')
  final String? contactEmail;

  @JsonKey(name: 'customer_type')
  final CustomerType customerType;

  @JsonKey(name: 'first_booking_at')
  final DateTime firstBookingAt;

  @JsonKey(name: 'last_booking_at')
  final DateTime lastBookingAt;

  @JsonKey(name: 'total_bookings')
  final int totalBookings;

  final String? notes;

  const FieldCustomer({
    required this.id,
    required this.fieldId,
    this.userId,
    required this.displayName,
    this.contactPhone,
    this.contactEmail,
    required this.customerType,
    required this.firstBookingAt,
    required this.lastBookingAt,
    required this.totalBookings,
    this.notes,
  });

  factory FieldCustomer.fromJson(Map<String, dynamic> json) =>
      _$FieldCustomerFromJson(json);

  Map<String, dynamic> toJson() => _$FieldCustomerToJson(this);
}
