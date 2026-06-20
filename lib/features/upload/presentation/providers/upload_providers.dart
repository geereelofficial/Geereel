import 'dart:io';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/presentation/providers/feed_providers.dart';

part 'upload_providers.g.dart';

/// 0.0-1.0 upload progress, observed separately from [UploadController]'s
/// success/error state so the progress bar can rebuild on every chunk
/// without re-triggering the whole post flow.
@riverpod
class UploadProgress extends _$UploadProgress {
  @override
  double build() => 0;

  void update(double value) => state = value;
}

@riverpod
class UploadController extends _$UploadController {
  @override
  FutureOr<void> build() {
    // Keep currentUserProfileProvider alive while this controller exists so that
    // ref.read(currentUserProfileProvider.future) in postMedia() doesn't race
    // with auto-disposal. Without this, the provider is disposed before the
    // profile fetch completes, causing a StateError.
    ref.listen(currentUserProfileProvider, (_, __) {});
  }

  Future<bool> postMedia({
    required File mediaFile,
    required MediaType mediaType,
    required String caption,
  }) async {
    // Read via `.future` rather than `.value`: right after sign-up the
    // profile fetch may not have completed yet, and `.value` would be null
    // even though the user is signed in. Must stay try/catch'd — this is a
    // plain method call (not AsyncNotifier.build()), so Riverpod won't
    // auto-catch a thrown exception into `state`; left unguarded, a
    // transient NetworkException here means the Post button silently does
    // nothing (no spinner, no error) instead of surfacing a retryable error.
    final UserEntity? profile;
    try {
      profile = await ref.read(currentUserProfileProvider.future);
    } catch (e) {
      state = AsyncError(_mapToFailure(e), StackTrace.current);
      return false;
    }
    if (profile == null) {
      state = AsyncError(const AuthFailure('You must be signed in to post.'), StackTrace.current);
      return false;
    }

    state = const AsyncLoading();
    ref.read(uploadProgressProvider.notifier).update(0);

    final Result<String> result;
    try {
      result = await ref.read(createPostUseCaseProvider).call(
        mediaFile: mediaFile,
        mediaType: mediaType,
        caption: caption,
        authorId: profile.uid,
        authorUsername: profile.username,
        authorPhotoUrl: profile.photoUrl,
        onProgress: (progress) => ref.read(uploadProgressProvider.notifier).update(progress),
      );
    } catch (e) {
      state = AsyncError(_mapToFailure(e), StackTrace.current);
      return false;
    }

    switch (result) {
      case Ok():
        state = const AsyncData(null);
        ref.invalidate(feedControllerProvider);
        return true;
      case Err(failure: final failure):
        state = AsyncError(failure, StackTrace.current);
        return false;
    }
  }

  Failure _mapToFailure(Object error) {
    if (error is StorageException) return StorageFailure(error.message);
    if (error is AuthException) return AuthFailure(error.message);
    if (error is NotFoundException) return NotFoundFailure(error.message);
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    // ignore: avoid_print
    print('DEBUG UploadCtrl unhandled: ${error.runtimeType}: $error');
    return ServerFailure('Upload error (${error.runtimeType}): $error');
  }
}
