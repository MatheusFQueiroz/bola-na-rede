class AvailabilitySlot {
  const AvailabilitySlot({
    required this.courtId,
    required this.courtName,
    required this.timeStart,
    required this.timeEnd,
    required this.isAvailable,
    this.price,
  });

  final String courtId;
  final String courtName;
  final String timeStart;
  final String timeEnd;
  final bool isAvailable;
  final double? price;
}
