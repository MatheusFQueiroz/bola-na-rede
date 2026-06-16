import 'package:json_annotation/json_annotation.dart';

import 'package:bolanarede_web/core/shared/enums.dart';
import 'package:bolanarede_web/core/shared/snapshots.dart';

part 'reservation.g.dart';

@JsonSerializable()
class Reservation {
  final String id;

  @JsonKey(name: 'field_id')
  final String fieldId;

  @JsonKey(name: 'court_id')
  final String? courtId;

  @JsonKey(name: 'recurring_plan_id')
  final String? recurringPlanId;

  final ReservationChannel channel;

  @JsonKey(name: 'channel_ref_id')
  final String? channelRefId;

  @JsonKey(name: 'booker_user_id')
  final String? bookerUserId;

  @JsonKey(name: 'booker_snapshot')
  final BookerSnapshot bookerSnapshot;

  final DateTime date;

  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  final double price;

  @JsonKey(name: 'platform_fee_pct')
  final double platformFeePct;

  @JsonKey(name: 'platform_fee_amt')
  final double platformFeeAmt;

  @JsonKey(name: 'net_amount')
  final double netAmount;

  final ReservationStatus status;

  @JsonKey(name: 'payment_status')
  final PaymentStatus paymentStatus;

  final String? notes;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  @JsonKey(name: 'cancelled_at')
  final DateTime? cancelledAt;

  @JsonKey(name: 'cancellation_reason')
  final String? cancellationReason;

  const Reservation({
    required this.id,
    required this.fieldId,
    this.courtId,
    this.recurringPlanId,
    required this.channel,
    this.channelRefId,
    this.bookerUserId,
    required this.bookerSnapshot,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.platformFeePct,
    required this.platformFeeAmt,
    required this.netAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);

  Map<String, dynamic> toJson() => _$ReservationToJson(this);
}
