import '../../../auth/domain/entities/user.dart';

abstract class ProfileRepository {
  Future<PlayerProfile> getProfile(String userId);
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId);
}
