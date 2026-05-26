import '../../../auth/domain/entities/user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_mock_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<PlayerProfile> getProfile(String userId) =>
      dataSource.getProfile(userId);

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) =>
      dataSource.getRecentMatches(userId);
}
