import 'dart:io';
import '../../../../core/utils/result.dart';
import '../entities/user_entity.dart';

/// Contract for authentication and current-user profile access.
///
/// Implemented by the data layer against Firebase; the domain/presentation
/// layers only ever see this interface.
abstract class AuthRepository {
  /// Emits the signed-in user's uid, or null when signed out.
  Stream<String?> watchAuthState();

  /// Live profile document for [uid], used to keep the UI in sync with
  /// denormalized counters (followers, posts, etc).
  Stream<UserEntity?> watchUserProfile(String uid);

  Future<Result<UserEntity>> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  });

  Future<Result<UserEntity>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Result<UserEntity>> signInWithGoogle();

  Future<Result<void>> signOut();

  Future<Result<void>> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
  });

  /// Uploads a new avatar to Storage and updates the profile's photoUrl.
  /// Returns the new photo URL.
  Future<Result<String>> uploadAvatar({required String uid, required File file});
}
