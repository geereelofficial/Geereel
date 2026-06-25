import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../datasources/comment_remote_data_source.dart';
import '../models/comment_model.dart';

class CommentRepositoryImpl implements CommentRepository {
  final CommentRemoteDataSource _remote;

  const CommentRepositoryImpl(this._remote);

  @override
  Future<Result<List<CommentEntity>>> fetchComments(
    String postId, {
    int limit = AppConstants.commentsPageSize,
    DateTime? before,
  }) async {
    try {
      final models = await _remote.getComments(postId, limit: limit, before: before);
      return Ok(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }

  @override
  Future<Result<CommentEntity>> addComment({
    required String postId,
    required String authorId,
    required String authorUsername,
    String? authorPhotoUrl,
    required String text,
  }) async {
    try {
      final model = await _remote.addComment(
        postId: postId,
        authorId: authorId,
        authorUsername: authorUsername,
        authorPhotoUrl: authorPhotoUrl,
        text: text,
      );
      return Ok(model.toEntity());
    } on ServerException catch (e) {
      return Err(ServerFailure(e.message));
    } catch (_) {
      return const Err(UnknownFailure());
    }
  }
}
