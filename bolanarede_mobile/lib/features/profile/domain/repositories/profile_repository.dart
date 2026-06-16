import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<PlayerProfile> getProfile(String userId);
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId);
}
