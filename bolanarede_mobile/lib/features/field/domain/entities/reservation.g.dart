// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
      id: json['id'] as String,
      fieldId: json['field_id'] as String,
      courtId: json['court_id'] as String?,
      recurringPlanId: json['recurring_plan_id'] as String?,
      channel: $enumDecode(_$ReservationChannelEnumMap, json['channel']),
      channelRefId: json['channel_ref_id'] as String?,
      bookerUserId: json['booker_user_id'] as String?,
      bookerSnapshot: BookerSnapshot.fromJson(
          json['booker_snapshot'] as Map<String, dynamic>),
      date: DateTime.parse(json['date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      price: (json['price'] as num).toDouble(),
      platformFeePct: (json['platform_fee_pct'] as num).toDouble(),
      platformFeeAmt: (json['platform_fee_amt'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      status: $enumDecode(_$ReservationStatusEnumMap, json['status']),
      paymentStatus:
          $enumDecode(_$PaymentStatusEnumMap, json['payment_status']),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      cancelledAt: json['cancelled_at'] == null
          ? null
          : DateTime.parse(json['cancelled_at'] as String),
      cancellationReason: json['cancellation_reason'] as String?,
    );

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'field_id': instance.fieldId,
      'court_id': instance.courtId,
      'recurring_plan_id': instance.recurringPlanId,
      'channel': _$ReservationChannelEnumMap[instance.channel]!,
      'channel_ref_id': instance.channelRefId,
      'booker_user_id': instance.bookerUserId,
      'booker_snapshot': instance.bookerSnapshot,
      'date': instance.date.toIso8601String(),
      'start_time': instance.startTime,
      'end_time': instance.endTime,
      'price': instance.price,
      'platform_fee_pct': instance.platformFeePct,
      'platform_fee_amt': instance.platformFeeAmt,
      'net_amount': instance.netAmount,
      'status': _$ReservationStatusEnumMap[instance.status]!,
      'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'cancelled_at': instance.cancelledAt?.toIso8601String(),
      'cancellation_reason': instance.cancellationReason,
    };

const _$ReservationChannelEnumMap = {
  ReservationChannel.bolanarededbApp: 'bolanarededb_app',
  ReservationChannel.manual: 'manual',
  ReservationChannel.whatsapp: 'whatsapp',
  ReservationChannel.phone: 'phone',
  ReservationChannel.link: 'link',
};

const _$ReservationStatusEnumMap = {
  ReservationStatus.pending: 'PENDING',
  ReservationStatus.confirmed: 'CONFIRMED',
  ReservationStatus.cancelled: 'CANCELLED',
  ReservationStatus.noShow: 'NO_SHOW',
  ReservationStatus.completed: 'COMPLETED',
};

const _$PaymentStatusEnumMap = {
  PaymentStatus.unpaid: 'UNPAID',
  PaymentStatus.paid: 'PAID',
  PaymentStatus.refunded: 'REFUNDED',
  PaymentStatus.external: 'EXTERNAL',
};
