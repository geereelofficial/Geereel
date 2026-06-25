import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';

/// Vertical, swipeable pager over one profile tab's posts (uploaded/liked/
/// reposted) — opened by tapping a tile in [PostsGrid] so the user keeps
/// scrolling through that profile's other videos/images instead of being
/// stuck on the single tapped post. Mirrors the main feed's paging
/// (preloaded adjacent video controllers, load-more near the end) but reads
/// from [profilePostsControllerProvider] so it shares pagination state with
/// the grid underneath it instead of re-fetching.
class ProfilePostViewerScreen extends ConsumerStatefulWidget {
  final String uid;
  final ProfilePostsTab tab;
  final String initialPostId;

  const ProfilePostViewerScreen({
    super.key,
    required this.uid,
    required this.tab,
    required this.initialPostId,
  });

  @override
  ConsumerState<ProfilePostViewerScreen> createState() => _ProfilePostViewerScreenState();
}

class _ProfilePostViewerScreenState extends ConsumerState<ProfilePostViewerScreen> with RouteAware {
  PageController? _pageController;
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _isCovered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController?.dispose();
    super.dispose();
  }

  // A further screen (e.g. a profile pushed by tapping the avatar/username
  // overlay) was pushed on top of this one.
  @override
  void didPushNext() {
    _isCovered = true;
    _applyVisibility();
  }

  @override
  void didPopNext() {
    _isCovered = false;
    _applyVisibility();
  }

  void _applyVisibility() {
    final controller = _controllers[_currentIndex];
    if (controller == null || !controller.value.isInitialized) return;
    if (!_isCovered) {
      if (!controller.value.isPlaying) controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  void _ensureInitialPage(List<PostEntity> posts) {
    if (_pageController != null) return;
    final index = posts.indexWhere((post) => post.postId == widget.initialPostId);
    _currentIndex = index == -1 ? 0 : index;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncControllers(posts);
    });
  }

  void _syncControllers(List<PostEntity> posts) {
    final keep = <int>{};
    for (final i in [_currentIndex - 1, _currentIndex, _currentIndex + 1]) {
      if (i >= 0 && i < posts.length && posts[i].mediaType == MediaType.video) {
        keep.add(i);
      }
    }

    final toRemove = _controllers.keys.where((i) => !keep.contains(i)).toList();
    for (final i in toRemove) {
      _controllers.remove(i)?.dispose();
    }

    for (final i in keep) {
      if (_controllers.containsKey(i)) continue;
      final controller = VideoPlayerController.networkUrl(Uri.parse(posts[i].mediaUrl));
      _controllers[i] = controller;
      controller.initialize().then((_) {
        if (!mounted) return;
        controller.setLooping(true);
        if (i == _currentIndex && !_isCovered) controller.play();
        setState(() {});
      });
    }

    for (final entry in _controllers.entries) {
      if (!entry.value.value.isInitialized) continue;
      if (entry.key == _currentIndex && !_isCovered) {
        if (!entry.value.value.isPlaying) entry.value.play();
      } else {
        if (entry.value.value.isPlaying) entry.value.pause();
      }
    }
  }

  void _onPageChanged(int index, List<PostEntity> posts) {
    setState(() => _currentIndex = index);
    _syncControllers(posts);
    ref.read(postRepositoryProvider).incrementViewCount(posts[index].postId);

    if (index >= posts.length - 2) {
      ref.read(profilePostsControllerProvider(widget.uid, widget.tab).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(profilePostsControllerProvider(widget.uid, widget.tab));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const ErrorView(message: 'This post could not be found.');
          }
          _ensureInitialPage(posts);

          return Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                itemCount: posts.length,
                onPageChanged: (index) => _onPageChanged(index, posts),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return VideoFeedItem(
                    post: post,
                    controller: post.mediaType == MediaType.video ? _controllers[index] : null,
                    isActive: index == _currentIndex,
                  );
                },
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(profilePostsControllerProvider(widget.uid, widget.tab)),
        ),
      ),
    );
  }
}
