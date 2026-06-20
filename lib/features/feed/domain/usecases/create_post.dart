import 'dart:io';
import '../../../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/post_repository.dart';

/// Used by both the upload feature (new posts) and could be reused for
/// re-uploads/retries; lives here because it operates on [PostRepository].
class CreatePost {
  final PostRepository _repository;

  const CreatePost(this._repository);

  Future<Result<String>> call({
    required File mediaFile,
    required MediaType mediaType,
    required String caption,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  }) {
    return _repository.createPost(
      mediaFile: mediaFile,
      mediaType: mediaType,
      caption: caption,
      authorId: authorId,
      authorUsername: authorUsername,
      authorPhotoUrl: authorPhotoUrl,
      durationSeconds: durationSeconds,
      width: width,
      height: height,
      onProgress: onProgress,
    );
  }
}
