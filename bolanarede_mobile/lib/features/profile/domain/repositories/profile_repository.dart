import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';

abstract class ProfileRepository {
  Future<PlayerProfile> getProfile(String userId);
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId);
  Future<PlayerProfile> updateProfile(UpdateProfileInput input);
}
