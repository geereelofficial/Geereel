import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/post_remote_data_source.dart';
import '../../data/repositories/post_repository_impl.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../../domain/usecases/create_post.dart';
import '../../domain/usecases/get_feed_page.dart';
import '../../domain/usecases/get_user_posts.dart';
import '../../domain/usecases/toggle_like.dart';

part 'feed_providers.g.dart';

@riverpod
PostRemoteDataSource postRemoteDataSource(Ref ref) {
  return ApiPostRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    cloudinaryUploader: ref.watch(cloudinaryUploaderProvider),
  );
}

@riverpod
PostRepository postRepository(Ref ref) {
  return PostRepositoryImpl(ref.watch(postRemoteDataSourceProvider));
}

@riverpod
GetFeedPage getFeedPageUseCase(Ref ref) => GetFeedPage(ref.watch(postRepositoryProvider));

@riverpod
ToggleLike toggleLikeUseCase(Ref ref) => ToggleLike(ref.watch(postRepositoryProvider));

@riverpod
CreatePost createPostUseCase(Ref ref) => CreatePost(ref.watch(postRepositoryProvider));

@riverpod
GetUserPosts getUserPostsUseCase(Ref ref) => GetUserPosts(ref.watch(postRepositoryProvider));

/// One-shot (non-paginated) post grid for a profile screen.
@riverpod
Future<List<PostEntity>> userPosts(Ref ref, String authorId) async {
  final result = await ref.watch(getUserPostsUseCaseProvider).call(authorId: authorId);
  return switch (result) {
    Ok(value: final posts) => posts,
    Err(failure: final failure) => throw failure,
  };
}

/// Live like state for one post, scoped to the currently signed-in user.
/// Each visible feed item watches its own doc so cost stays proportional
/// to what's on screen rather than the whole feed page.
@riverpod
Stream<bool> isPostLiked(Ref ref, String postId) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(false);
  return ref.watch(postRepositoryProvider).watchIsLiked(postId: postId, uid: uid);
}

/// Paginated reverse-chronological global feed.
@riverpod
class FeedController extends _$FeedController {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<PostEntity>> build() async {
    _hasMore = true;
    final result = await ref.read(getFeedPageUseCaseProvider).call();
    return switch (result) {
      Ok(value: final posts) => posts,
      Err(failure: final failure) => throw failure,
    };
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.value;
    if (current == null || current.isEmpty) return;

    _isLoadingMore = true;
    final result = await ref.read(getFeedPageUseCaseProvider).call(
      startAfterCreatedAt: current.last.createdAt,
    );
    _isLoadingMore = false;

    switch (result) {
      case Ok(value: final newPosts):
        if (newPosts.length < AppConstants.feedPageSize) _hasMore = false;
        state = AsyncData([...current, ...newPosts]);
      case Err():
        // Keep showing the existing page; the user can pull to refresh.
        break;
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }

  Future<void> toggleLike(String postId) async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null) return;
    await ref.read(toggleLikeUseCaseProvider).call(postId: postId, uid: uid);
  }
}
