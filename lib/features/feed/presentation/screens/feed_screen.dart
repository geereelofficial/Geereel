import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../status/presentation/widgets/status_tray.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import '../widgets/feed_top_bar.dart';
import '../widgets/video_feed_item.dart';

/// Vertical, full-screen, swipeable video/image feed — the app's home tab.
///
/// Hosts the TikTok-style [FeedTopBar] (Following / For You / search) as an
/// overlay above the page view; the page view itself is keyed by the
/// selected [FeedTab] so switching tabs tears down and rebuilds pagination
/// and video controllers from scratch rather than mixing two feeds' state.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedFeedTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          ColoredBox(
            color: const Color(0xFF1A1A1A),
            child: SafeArea(
              bottom: false,
              child: Column(children: [FeedTopBar(), StatusTray()]),
            ),
          ),
          Expanded(
            child: _FeedPageView(key: ValueKey(selectedTab), tab: selectedTab),
          ),
        ],
      ),
    );
  }
}

class _FeedPageView extends ConsumerStatefulWidget {
  final FeedTab tab;

  const _FeedPageView({super.key, required this.tab});

  @override
  ConsumerState<_FeedPageView> createState() => _FeedPageViewState();
}

class _FeedPageViewState extends ConsumerState<_FeedPageView> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  final Map<int, VideoPlayerController> _controllers = {};
  int _currentIndex = 0;
  bool _appInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appInForeground = state == AppLifecycleState.resumed;
    _applyVisibility();
  }

  /// Whether the active video is allowed to play right now: the Feed tab
  /// must be the visible bottom-nav branch (not Chat/Profile), the app must
  /// be in the foreground (not backgrounded/locked), and no other screen
  /// (e.g. a profile pushed by tapping the avatar/username) must be covering
  /// the feed.
  bool get _shouldPlay =>
      _appInForeground &&
      ref.read(feedTabActiveProvider) &&
      !ref.read(isShellCoveredProvider);

  /// Re-applies [_shouldPlay] to the current page's controller without
  /// touching pagination or adjacent preloaded controllers — used whenever
  /// visibility changes rather than the page itself.
  void _applyVisibility() {
    final controller = _controllers[_currentIndex];
    if (controller == null || !controller.value.isInitialized) return;
    if (_shouldPlay) {
      if (!controller.value.isPlaying) controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
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
        if (i == _currentIndex && _shouldPlay) controller.play();
        setState(() {});
      });
    }

    for (final entry in _controllers.entries) {
      if (!entry.value.value.isInitialized) continue;
      if (entry.key == _currentIndex && _shouldPlay) {
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
      ref.read(feedControllerProvider(widget.tab).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedControllerProvider(widget.tab));
    ref.listen(feedTabActiveProvider, (_, _) => _applyVisibility());
    ref.listen(isShellCoveredProvider, (_, _) => _applyVisibility());

    return feedAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return Center(
            child: Text(
              widget.tab == FeedTab.following
                  ? 'Posts from accounts you follow will show up here.'
                  : 'No posts yet — be the first to share one!',
              textAlign: TextAlign.center,
            ),
          );
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_controllers.isEmpty) _syncControllers(posts);
        });

        return RefreshIndicator(
          onRefresh: () => ref.read(feedControllerProvider(widget.tab).notifier).refresh(),
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
        onRetry: () => ref.invalidate(feedControllerProvider(widget.tab)),
      ),
    );
  }
}
