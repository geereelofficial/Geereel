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
import '../../domain/usecases/get_following_feed_page.dart';
import '../../domain/usecases/get_user_posts.dart';
import '../../domain/usecases/toggle_bookmark.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/toggle_repost.dart';

part 'feed_providers.g.dart';

/// Which top-bar tab the feed screen is showing.
enum FeedTab { forYou, following }

/// Currently selected top-bar tab; defaults to "For You" like TikTok.
@riverpod
class SelectedFeedTab extends _$SelectedFeedTab {
  @override
  FeedTab build() => FeedTab.forYou;

  void select(FeedTab tab) => state = tab;
}

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
GetFollowingFeedPage getFollowingFeedPageUseCase(Ref ref) =>
    GetFollowingFeedPage(ref.watch(postRepositoryProvider));

@riverpod
ToggleLike toggleLikeUseCase(Ref ref) => ToggleLike(ref.watch(postRepositoryProvider));

@riverpod
ToggleBookmark toggleBookmarkUseCase(Ref ref) => ToggleBookmark(ref.watch(postRepositoryProvider));

@riverpod
ToggleRepost toggleRepostUseCase(Ref ref) => ToggleRepost(ref.watch(postRepositoryProvider));

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

/// (isActive, displayCount) pair for a toggleable per-post action
/// (like/bookmark/repost).
typedef ToggleState = (bool isActive, int count);

/// Paginated reverse-chronological feed, keyed by [FeedTab] so "For You"
/// (global) and "Following" keep independent pagination/scroll state.
@riverpod
class FeedController extends _$FeedController {
  bool _hasMore = true;
  bool _isLoadingMore = false;

  Future<Result<List<PostEntity>>> _fetchPage(FeedTab tab, {DateTime? startAfterCreatedAt}) {
    return tab == FeedTab.forYou
        ? ref.read(getFeedPageUseCaseProvider).call(startAfterCreatedAt: startAfterCreatedAt)
        : ref.read(getFollowingFeedPageUseCaseProvider).call(startAfterCreatedAt: startAfterCreatedAt);
  }

  @override
  Future<List<PostEntity>> build(FeedTab tab) async {
    _hasMore = true;
    final result = await _fetchPage(tab);
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
    final result = await _fetchPage(tab, startAfterCreatedAt: current.last.createdAt);
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
}

/// Like state + count for one post, keyed by postId so each visible feed
/// item tracks its own toggle independently of which feed tab is on screen.
///
/// [initialCount] seeds the displayed count from the post entity already in
/// memory (avoiding a redundant fetch); toggling flips the active state and
/// adjusts the count optimistically, then reverts both if the request fails
/// — this is what makes tapping the heart twice reliably round-trip between
/// liked and unliked instead of getting stuck out of sync with the server.
@riverpod
class LikeController extends _$LikeController {
  @override
  Future<ToggleState> build(String postId, int initialCount) async {
    final uid = ref.watch(authStateProvider).value;
    final isLiked = uid == null
        ? false
        : await ref.watch(postRepositoryProvider).watchIsLiked(postId: postId, uid: uid).first;
    return (isLiked, initialCount);
  }

  Future<void> toggle() async {
    final uid = ref.read(authStateProvider).value;
    final current = state.value;
    if (uid == null || current == null) return;

    final (isActive, count) = current;
    state = AsyncData((!isActive, isActive ? count - 1 : count + 1));

    final result = await ref.read(toggleLikeUseCaseProvider).call(postId: postId, uid: uid);
    if (result case Err()) state = AsyncData(current);
  }
}

/// Bookmark state + count for one post, mirroring [LikeController].
@riverpod
class BookmarkController extends _$BookmarkController {
  @override
  Future<ToggleState> build(String postId, int initialCount) async {
    final uid = ref.watch(authStateProvider).value;
    final isBookmarked = uid == null
        ? false
        : await ref.watch(postRepositoryProvider).watchIsBookmarked(postId: postId, uid: uid).first;
    return (isBookmarked, initialCount);
  }

  Future<void> toggle() async {
    final uid = ref.read(authStateProvider).value;
    final current = state.value;
    if (uid == null || current == null) return;

    final (isActive, count) = current;
    state = AsyncData((!isActive, isActive ? count - 1 : count + 1));

    final result = await ref.read(toggleBookmarkUseCaseProvider).call(postId: postId, uid: uid);
    if (result case Err()) state = AsyncData(current);
  }
}

/// Repost state + count for one post, mirroring [LikeController].
@riverpod
class RepostController extends _$RepostController {
  @override
  Future<ToggleState> build(String postId, int initialCount) async {
    final uid = ref.watch(authStateProvider).value;
    final isReposted = uid == null
        ? false
        : await ref.watch(postRepositoryProvider).watchIsReposted(postId: postId, uid: uid).first;
    return (isReposted, initialCount);
  }

  Future<void> toggle() async {
    final uid = ref.read(authStateProvider).value;
    final current = state.value;
    if (uid == null || current == null) return;

    final (isActive, count) = current;
    state = AsyncData((!isActive, isActive ? count - 1 : count + 1));

    final result = await ref.read(toggleRepostUseCaseProvider).call(postId: postId, uid: uid);
    if (result case Err()) state = AsyncData(current);
  }
}
