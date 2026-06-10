// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FieldCustomer _$FieldCustomerFromJson(Map<String, dynamic> json) =>
    FieldCustomer(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      userId: json['user_id'] as String?,
      displayName: json['display_name'] as String,
      contactPhone: json['contact_phone'] as String?,
      contactEmail: json['contact_email'] as String?,
      customerType: $enumDecode(_$CustomerTypeEnumMap, json['customer_type']),
      firstBookingAt: DateTime.parse(json['first_booking_at'] as String),
      lastBookingAt: DateTime.parse(json['last_booking_at'] as String),
      totalBookings: (json['total_bookings'] as num).toInt(),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$FieldCustomerToJson(FieldCustomer instance) =>
    <String, dynamic>{
      'id': instance.id,
      'field_id': instance.fieldId,
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'contact_phone': instance.contactPhone,
      'contact_email': instance.contactEmail,
      'customer_type': _$CustomerTypeEnumMap[instance.customerType]!,
      'first_booking_at': instance.firstBookingAt.toIso8601String(),
      'last_booking_at': instance.lastBookingAt.toIso8601String(),
      'total_bookings': instance.totalBookings,
      'notes': instance.notes,
    };

const _$CustomerTypeEnumMap = {
  CustomerType.individual: 'individual',
  CustomerType.group: 'group',
  CustomerType.team: 'team',
};
