import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/utils/smooth_page_physics.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../comments/presentation/widgets/comment_bottom_sheet.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../../../feed/presentation/widgets/video_feed_item.dart';

/// Vertical, swipeable pager over one profile tab's posts — opened by tapping
/// a tile in [PostsGrid]. Comments overlay floats on the video; a hint bar at
/// the bottom opens the full white comment sheet on tap.
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
  String? _currentPostId;
  int _currentCommentCount = 0;

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
    _currentPostId = posts[_currentIndex].postId;
    _currentCommentCount = posts[_currentIndex].commentsCount;
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
    setState(() {
      _currentIndex = index;
      _currentPostId = posts[index].postId;
      _currentCommentCount = posts[index].commentsCount;
    });
    _syncControllers(posts);
    ref.read(postRepositoryProvider).incrementViewCount(posts[index].postId);

    if (index >= posts.length - 2) {
      ref.read(profilePostsControllerProvider(widget.uid, widget.tab).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(profilePostsControllerProvider(widget.uid, widget.tab));
    final statusBarHeight = MediaQuery.of(context).padding.top;

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
                physics: const SmoothPagePhysics(parent: BouncingScrollPhysics()),
                itemCount: posts.length,
                onPageChanged: (index) => _onPageChanged(index, posts),
                itemBuilder: (context, index) {
                  final post = posts[index];
                  return VideoFeedItem(
                    post: post,
                    controller: post.mediaType == MediaType.video ? _controllers[index] : null,
                    isActive: index == _currentIndex,
                    contentBottomOffset: 40,
                  );
                },
              ),
              // Full-width dark strip at the very bottom with the frosted comment
              // field sitting inside it. Right padding reserves space so the field
              // doesn't extend under the action-buttons column.
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: AppColors.background,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 100, 8),
                      child: GestureDetector(
                        onTap: _currentPostId == null
                            ? null
                            : () => showCommentBottomSheet(
                                  context,
                                  postId: _currentPostId!,
                                  initialCommentCount: _currentCommentCount,
                                ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.mode_comment_outlined, color: AppColors.textSecondary, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Add a comment...',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Dark strip only behind the status bar.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(color: const Color(0xFF1A1A1A), height: statusBarHeight),
              ),
              Positioned(
                top: statusBarHeight,
                left: 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/feed'),
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
