import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import '../widgets/video_feed_item.dart';

/// Vertical, full-screen, swipeable video/image feed — the app's home tab.
///
/// Keeps one [VideoPlayerController] per video post in a window of
/// [_currentIndex] - 1 .. +1, so the next video is already buffering by
/// the time the user swipes to it, without holding controllers for the
/// entire fetched page in memory.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
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
        if (i == _currentIndex) controller.play();
        setState(() {});
      });
    }

    for (final entry in _controllers.entries) {
      if (!entry.value.value.isInitialized) continue;
      if (entry.key == _currentIndex) {
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
      ref.read(feedControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: feedAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Text('No posts yet — be the first to share one!'),
            );
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_controllers.isEmpty) _syncControllers(posts);
          });

          return RefreshIndicator(
            onRefresh: () => ref.read(feedControllerProvider.notifier).refresh(),
            child: PageView.builder(
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
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: 'Could not load the feed.\n$error',
          onRetry: () => ref.invalidate(feedControllerProvider),
        ),
      ),
    );
  }
}
