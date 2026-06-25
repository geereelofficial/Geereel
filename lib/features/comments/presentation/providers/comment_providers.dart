import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
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

/// Paginated, newest-first comment list for one post — loads
/// [AppConstants.commentsPageSize] at a time as the sheet is scrolled
/// rather than fetching the whole thread up front, and supports inserting a
/// freshly-posted comment locally so posting doesn't refetch/jump-scroll
/// the whole list.
@riverpod
class CommentsController extends _$CommentsController {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<CommentEntity>> build(String postId) async {
    _hasMore = true;
    final result = await ref.read(getCommentsUseCaseProvider).call(postId);
    return switch (result) {
      Ok(value: final comments) => comments,
      Err(failure: final failure) => throw failure,
    };
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;

    _isLoadingMore = true;
    final result = await ref
        .read(getCommentsUseCaseProvider)
        .call(postId, before: current.last.createdAt);
    _isLoadingMore = false;

    switch (result) {
      case Ok(value: final newComments):
        if (newComments.length < AppConstants.commentsPageSize) _hasMore = false;
        state = AsyncData([...current, ...newComments]);
      case Err():
        // Keep showing the existing page; the user can pull to retry.
        break;
    }
  }

  void prependLocal(CommentEntity comment) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData([comment, ...current]);
  }
}

/// Local comment-count overlay for one post, mirroring [LikeController] —
/// the feed action button shows this instead of the immutable [PostEntity]
/// count so a newly-posted comment is reflected immediately without
/// refetching the whole feed.
@riverpod
class CommentCountController extends _$CommentCountController {
  @override
  int build(String postId, int initialCount) => initialCount;

  void increment() => state++;
}
