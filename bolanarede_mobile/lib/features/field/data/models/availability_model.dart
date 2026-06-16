import 'package:bola_na_rede/features/field/domain/entities/availability.dart';

class AvailabilitySlotModel {
  const AvailabilitySlotModel({
    required this.courtId,
    required this.courtName,
    required this.timeStart,
    required this.timeEnd,
    required this.isAvailable,
  });

  final String courtId;
  final String courtName;
  final String timeStart;
  final String timeEnd;
  final bool isAvailable;

  AvailabilitySlot toEntity() => AvailabilitySlot(
        courtId: courtId,
        courtName: courtName,
        timeStart: timeStart,
        timeEnd: timeEnd,
        isAvailable: isAvailable,
      );

  static List<AvailabilitySlotModel> fromFieldAvailabilityJson(
    Map<String, dynamic> json,
  ) {
    final courts = json['courts'] as List<dynamic>? ?? [];
    final result = <AvailabilitySlotModel>[];
    for (final court in courts) {
      final courtMap = court as Map<String, dynamic>;
      final courtId = courtMap['courtId'] as String;
      final courtName = courtMap['courtName'] as String;
      final slots = courtMap['slots'] as List<dynamic>? ?? [];
      for (final slot in slots) {
        final slotMap = slot as Map<String, dynamic>;
        result.add(
          AvailabilitySlotModel(
            courtId: courtId,
            courtName: courtName,
            timeStart: slotMap['startTime'] as String,
            timeEnd: slotMap['endTime'] as String,
            isAvailable: slotMap['isAvailable'] as bool,
          ),
        );
      }
    }
    return result;
  }
}
