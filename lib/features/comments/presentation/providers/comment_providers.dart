import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/api_providers.dart';
import '../../data/datasources/comment_remote_data_source.dart';
import '../../data/repositories/comment_repository_impl.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/repositories/comment_repository.dart';
import '../../domain/usecases/add_comment.dart';
import '../../domain/usecases/get_comments.dart';

part 'comment_providers.g.dart';

@riverpod
CommentRemoteDataSource commentRemoteDataSource(Ref ref) {
  return ApiCommentRemoteDataSource(apiClient: ref.watch(apiClientProvider));
}

@riverpod
CommentRepository commentRepository(Ref ref) {
  return CommentRepositoryImpl(ref.watch(commentRemoteDataSourceProvider));
}

@riverpod
GetComments getCommentsUseCase(Ref ref) => GetComments(ref.watch(commentRepositoryProvider));

@riverpod
AddComment addCommentUseCase(Ref ref) => AddComment(ref.watch(commentRepositoryProvider));

@riverpod
Stream<List<CommentEntity>> postComments(Ref ref, String postId) {
  return ref.watch(getCommentsUseCaseProvider).call(postId);
}
