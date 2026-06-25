import 'dart:io';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;

  const AuthRepositoryImpl(this._remote);

  @override
  Stream<String?> watchAuthState() => _remote.watchAuthState();

  @override
  Stream<UserEntity?> watchUserProfile(String uid) {
    return _remote.watchUserProfile(uid).map((model) => model?.toEntity());
  }

  @override
  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    try {
      final model = await _remote.signUpWithEmail(
        email: email,
        password: password,
        username: username,
        displayName: displayName,
      );
      return Ok(model.toEntity());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _remote.signInWithEmail(email: email, password: password);
      return Ok(model.toEntity());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<UserEntity>> signInWithGoogle() async {
    try {
      final model = await _remote.signInWithGoogle();
      return Ok(model.toEntity());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remote.signOut();
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
  }) async {
    try {
      await _remote.updateProfile(uid: uid, displayName: displayName, bio: bio);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<String>> uploadAvatar({required String uid, required File file}) async {
    try {
      final url = await _remote.uploadAvatar(uid: uid, file: file);
      return Ok(url);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> followUser(String targetUid) async {
    try {
      await _remote.followUser(targetUid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> unfollowUser(String targetUid) async {
    try {
      await _remote.unfollowUser(targetUid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<bool>> isFollowing(String targetUid) async {
    try {
      return Ok(await _remote.isFollowing(targetUid));
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<UserEntity>>> searchUsers(String query) async {
    try {
      final models = await _remote.searchUsers(query);
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<UserEntity>>> getFollowers(
    String uid, {
    required int page,
    int limit = AppConstants.followListPageSize,
  }) async {
    try {
      final models = await _remote.getFollowers(uid, page: page, limit: limit);
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<List<UserEntity>>> getFollowing(
    String uid, {
    required int page,
    int limit = AppConstants.followListPageSize,
  }) async {
    try {
      final models = await _remote.getFollowing(uid, page: page, limit: limit);
      return Ok(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  Failure _mapToFailure(Object error) {
    if (error is AuthException) return AuthFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    return const UnknownFailure();
  }
}
