import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/providers/navigation_providers.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../comments/presentation/widgets/comment_bottom_sheet.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import '../widgets/video_feed_item.dart';

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
  int _commentCount = 0;

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
    _commentCount = post.commentsCount;

    final controller = VideoPlayerController.networkUrl(Uri.parse(post.mediaUrl));
    _controller = controller;
    controller.initialize().then((_) {
      if (!mounted) return;
      controller.setLooping(true);
      if (!_isCovered) controller.play();
      setState(() {});
    });
  }

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
    final statusBarHeight = MediaQuery.of(context).padding.top;

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
                contentBottomOffset: 40,
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(singlePostProvider(widget.postId)),
            ),
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
                    onTap: () => showCommentBottomSheet(
                      context,
                      postId: widget.postId,
                      initialCommentCount: _commentCount,
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
      ),
    );
  }
}
