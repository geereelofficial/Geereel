import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../domain/entities/post_entity.dart';
import 'feed_action_buttons.dart';

/// One full-screen page of the feed: the media (video or image) plus the
/// caption/username overlay and the right-hand action button column.
///
/// The [controller] is created and disposed by [FeedScreen], not by this
/// widget, so it can be preloaded one page ahead of [isActive].
class VideoFeedItem extends StatefulWidget {
  final PostEntity post;
  final VideoPlayerController? controller;
  final bool isActive;

  const VideoFeedItem({
    super.key,
    required this.post,
    required this.controller,
    required this.isActive,
  });

  @override
  State<VideoFeedItem> createState() => _VideoFeedItemState();
}

class _VideoFeedItemState extends State<VideoFeedItem> {
  bool _showPauseIcon = false;

  void _togglePlayback() {
    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) return;
    setState(() {
      if (controller.value.isPlaying) {
        controller.pause();
        _showPauseIcon = true;
      } else {
        controller.play();
        _showPauseIcon = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.post.mediaType == MediaType.video ? _togglePlayback : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(),
          const _BottomGradient(),
          Positioned(
            left: 16,
            right: 88,
            bottom: 24,
            child: _PostInfo(post: widget.post),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: FeedActionButtons(post: widget.post),
          ),
          if (_showPauseIcon)
            const Center(
              child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
            ),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    final post = widget.post;
    if (post.mediaType == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: post.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(color: AppColors.surface),
        errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surface),
      );
    }

    final controller = widget.controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: AppColors.surface);
    }

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, AppColors.overlay],
            stops: [0.6, 1.0],
          ),
        ),
      ),
    );
  }
}

class _PostInfo extends StatelessWidget {
  final PostEntity post;

  const _PostInfo({required this.post});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('@${post.authorUsername}', style: AppTextStyles.username),
        if (post.caption.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            post.caption,
            style: AppTextStyles.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
