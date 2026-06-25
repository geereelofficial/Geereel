import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import '../widgets/video_feed_item.dart';

/// Single-post screen opened from a shared post link (`geereel://post/:id`)
/// rather than from the paginated feed — reuses [VideoFeedItem] but manages
/// its own one-off [VideoPlayerController] since there's no adjacent page to
/// preload/sync against here.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> with RouteAware {
  VideoPlayerController? _controller;
  String? _initializedForPostId;
  bool _isCovered = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _controller?.dispose();
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

  void _ensureController(PostEntity post) {
    if (_initializedForPostId == post.postId || post.mediaType != MediaType.video) return;
    _initializedForPostId = post.postId;

    final controller = VideoPlayerController.networkUrl(Uri.parse(post.mediaUrl));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      controller.setLooping(true);
      if (!_isCovered) controller.play();
      setState(() {});
    });
  }

  /// Re-applies play/pause when a route covers or uncovers this screen.
  void _applyVisibility() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (!_isCovered) {
      if (!controller.value.isPlaying) controller.play();
    } else if (controller.value.isPlaying) {
      controller.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(singlePostProvider(widget.postId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          postAsync.when(
            data: (post) {
              _ensureController(post);
              return VideoFeedItem(
                post: post,
                controller: post.mediaType == MediaType.video ? _controller : null,
                isActive: true,
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(singlePostProvider(widget.postId)),
            ),
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
      ),
    );
  }
}
