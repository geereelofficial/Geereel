import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_with_email.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_email.dart';
import '../../domain/usecases/update_profile.dart';
import '../../domain/usecases/upload_avatar.dart';

part 'auth_providers.g.dart';

@riverpod
AuthRemoteDataSource authRemoteDataSource(Ref ref) {
  return ApiAuthRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    cloudinaryUploader: ref.watch(cloudinaryUploaderProvider),
  );
}

@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
}

@riverpod
SignUpWithEmail signUpWithEmailUseCase(Ref ref) => SignUpWithEmail(ref.watch(authRepositoryProvider));

@riverpod
SignInWithEmail signInWithEmailUseCase(Ref ref) => SignInWithEmail(ref.watch(authRepositoryProvider));

@riverpod
SignInWithGoogle signInWithGoogleUseCase(Ref ref) => SignInWithGoogle(ref.watch(authRepositoryProvider));

@riverpod
SignOut signOutUseCase(Ref ref) => SignOut(ref.watch(authRepositoryProvider));

@riverpod
UpdateProfile updateProfileUseCase(Ref ref) => UpdateProfile(ref.watch(authRepositoryProvider));

@riverpod
UploadAvatar uploadAvatarUseCase(Ref ref) => UploadAvatar(ref.watch(authRepositoryProvider));

/// Emits the signed-in user's uid, or null when signed out. Drives the
/// router's auth redirect.
@riverpod
Stream<String?> authState(Ref ref) {
  return ref.watch(authRepositoryProvider).watchAuthState();
}

/// Live Firestore profile of whoever is currently signed in.
@riverpod
Stream<UserEntity?> currentUserProfile(Ref ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).watchUserProfile(uid);
}

/// Live Firestore profile for an arbitrary [uid], used by the profile
/// screen when viewing someone other than the signed-in user.
@riverpod
Stream<UserEntity?> userProfile(Ref ref, String uid) {
  return ref.watch(authRepositoryProvider).watchUserProfile(uid);
}

/// Drives the login/signup screens: exposes loading/error state for the
/// in-flight auth action without the UI touching [Result] directly.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<bool> signUpWithEmail({
    required String email,
    required String password,
    required String username,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(signUpWithEmailUseCaseProvider).call(
      email: email,
      password: password,
      username: username,
      displayName: displayName,
    );
    return _handle(result);
  }

  Future<bool> signInWithEmail({required String email, required String password}) async {
    state = const AsyncLoading();
    final result = await ref.read(signInWithEmailUseCaseProvider).call(
      email: email,
      password: password,
    );
    return _handle(result);
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    final result = await ref.read(signInWithGoogleUseCaseProvider).call();
    return _handle(result);
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await ref.read(signOutUseCaseProvider).call();
    switch (result) {
      case Ok():
        state = const AsyncData(null);
      case Err(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
    }
  }

  bool _handle(Result result) {
    switch (result) {
      case Ok():
        state = const AsyncData(null);
        return true;
      case Err(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}

/// Drives the edit-profile screen: bio/display name updates and avatar
/// uploads, both invalidating [currentUserProfileProvider] on success.
@riverpod
class EditProfileController extends _$EditProfileController {
  @override
  FutureOr<void> build() {}

  Future<bool> updateProfile({
    required String uid,
    String? displayName,
    String? bio,
  }) async {
    state = const AsyncLoading();
    final result = await ref.read(updateProfileUseCaseProvider).call(
      uid: uid,
      displayName: displayName,
      bio: bio,
    );
    return _handle(result);
  }

  Future<bool> uploadAvatar({required String uid, required File file}) async {
    state = const AsyncLoading();
    final result = await ref.read(uploadAvatarUseCaseProvider).call(uid: uid, file: file);
    return switch (result) {
      Ok() => _handle(const Ok(null)),
      Err(failure: final failure) => _handle(Err(failure)),
    };
  }

  bool _handle(Result result) {
    switch (result) {
      case Ok():
        state = const AsyncData(null);
        return true;
      case Err(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }
}
