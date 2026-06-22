import 'package:bola_na_rede/features/auth/domain/entities/user.dart';
import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/update_profile_input.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileDataSource dataSource;

  ProfileRepositoryImpl({required this.dataSource});

  @override
  Future<PlayerProfile> getProfile(String userId) =>
      dataSource.getProfile(userId);

  @override
  Future<List<Map<String, dynamic>>> getRecentMatches(String userId) =>
      dataSource.getRecentMatches(userId);

  @override
  Future<PlayerProfile> updateProfile(UpdateProfileInput input) =>
      dataSource.updateProfile(input);
}
