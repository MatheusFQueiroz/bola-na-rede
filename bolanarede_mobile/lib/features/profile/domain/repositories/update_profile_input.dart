import 'package:bola_na_rede/core/shared/enums.dart';

class UpdateProfileInput {
  const UpdateProfileInput({
    required this.displayName,
    this.city,
    this.bio,
    this.position,
    this.skillLevel,
    this.isPublic,
  });

  final String displayName;
  final String? city;
  final String? bio;
  final PlayerPosition? position;
  final int? skillLevel;
  final bool? isPublic;
}
