import 'package:bola_na_rede/features/field/domain/entities/field.dart';

class FieldModel {
  const FieldModel({
    required this.id,
    required this.name,
    required this.description,
    required this.city,
    required this.address,
    required this.lat,
    required this.lng,
    required this.ownerUserId,
    required this.isActive,
    required this.createdAt,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) => FieldModel(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        city: json['city'] as String? ?? '',
        address: json['address'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        ownerUserId: json['ownerUserId'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  final String id;
  final String name;
  final String? description;
  final String city;
  final String address;
  final double? lat;
  final double? lng;
  final String ownerUserId;
  final bool isActive;
  final DateTime createdAt;

  Field toEntity() => Field(
        id: id,
        ownerUserId: ownerUserId,
        name: name,
        description: description,
        street: address.isNotEmpty ? address : null,
        city: city,
        state: '',
        latitude: lat,
        longitude: lng,
        status: isActive ? FieldStatus.active : FieldStatus.inactive,
        plan: FieldPlan.pro,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
}

class FieldCourtModel {
  const FieldCourtModel({
    required this.id,
    required this.fieldId,
    required this.name,
    required this.type,
    required this.maxPlayers,
    required this.isActive,
  });

  factory FieldCourtModel.fromJson(Map<String, dynamic> json) =>
      FieldCourtModel(
        id: json['id'] as String,
        fieldId: json['fieldId'] as String? ?? '',
        name: json['name'] as String,
        type: json['type'] as String? ?? '',
        maxPlayers: json['maxPlayers'] as int? ?? 0,
        isActive: json['isActive'] as bool? ?? true,
      );

  final String id;
  final String fieldId;
  final String name;
  final String type;
  final int maxPlayers;
  final bool isActive;

  FieldCourt toEntity() => FieldCourt(
        id: id,
        fieldId: fieldId,
        name: name,
        modality: _parseModality(type),
        capacity: maxPlayers,
        isActive: isActive,
      );

  static CourtModality _parseModality(String type) {
    switch (type) {
      case 'futsal':
        return CourtModality.futsal;
      case 'salao':
        return CourtModality.salao;
      case 'society':
        return CourtModality.society;
      default:
        return CourtModality.society;
    }
  }
}
