import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';
import 'feed_action_buttons.dart';
import 'repost_options_sheet.dart';

/// One full-screen page of the feed: the media (video or image) plus the
/// caption/username overlay and the right-hand action button column.
///
/// The [controller] is created and disposed by [FeedScreen], not by this
/// widget, so it can be preloaded one page ahead of [isActive].
class VideoFeedItem extends StatelessWidget {
  final PostEntity post;
  final VideoPlayerController? controller;
  final bool isActive;

  const VideoFeedItem({
    super.key,
    required this.post,
    required this.controller,
    required this.isActive,
  });

  void _togglePlayback() {
    final controller = this.controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: post.mediaType == MediaType.video ? _togglePlayback : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildMedia(),
          const _BottomGradient(),
          Positioned(
            left: 16,
            right: 88,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _RepostButton(post: post),
                const SizedBox(height: 10),
                _PostInfo(post: post),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 24,
            child: FeedActionButtons(post: post),
          ),
          _PauseIndicator(controller: controller),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (post.mediaType == MediaType.image) {
      return CachedNetworkImage(
        imageUrl: post.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (_, _) => const ColoredBox(color: AppColors.surface),
        errorWidget: (_, _, _) => const ColoredBox(color: AppColors.surface),
      );
    }

    final controller = this.controller;
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

/// Center play-arrow overlay shown only while the video is paused — driven
/// by the controller's actual playback state (autoplay, a manual tap,
/// navigating away and back, the app backgrounding, ...) rather than a
/// locally tracked flag, so it can never drift out of sync with what's
/// really playing: it appears exactly when paused and disappears exactly
/// when playing.
class _PauseIndicator extends StatelessWidget {
  final VideoPlayerController? controller;

  const _PauseIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) return const SizedBox.shrink();

    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        if (!value.isInitialized || value.isPlaying) return const SizedBox.shrink();
        return const Center(
          child: Icon(Icons.play_arrow, color: Colors.white70, size: 72),
        );
      },
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

/// Repost pill, positioned above the username/caption like TikTok's repost
/// affordance. Filled with [AppColors.secondary] once reposted, matching the
/// Follow button's solid-color style.
class _RepostButton extends ConsumerWidget {
  final PostEntity post;

  const _RepostButton({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repostProvider = repostControllerProvider(post.postId, post.repostsCount, post.reposted);
    final (isReposted, repostCount) = ref.watch(repostProvider);

    return GestureDetector(
      onTap: () => showRepostOptionsSheet(context, post),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isReposted ? AppColors.secondary : Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.repeat, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              isReposted
                  ? 'Reposted${repostCount > 0 ? ' · ${Formatters.compactCount(repostCount)}' : ''}'
                  : 'Repost',
              style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostInfo extends ConsumerWidget {
  final PostEntity post;

  const _PostInfo({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                '@${post.authorUsername}',
                style: AppTextStyles.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),
            _InlineFollowButton(post: post),
          ],
        ),
        if (post.repostComment != null && post.repostComment!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.format_quote, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    post.repostComment!,
                    style: AppTextStyles.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
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

/// Small "Follow" pill shown right after the username — hidden for your own
/// posts and once you already follow the author, mirroring the avatar's "+"
/// quick-follow badge but as an explicit labelled action next to the name.
class _InlineFollowButton extends ConsumerWidget {
  final PostEntity post;

  const _InlineFollowButton({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value;
    final isOwnPost = myUid == null || myUid == post.authorId;
    if (isOwnPost) return const SizedBox.shrink();

    final followProvider = feedFollowControllerProvider(post.authorId, post.isFollowingAuthor);
    final isFollowing = ref.watch(followProvider);
    if (isFollowing) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => ref.read(followProvider.notifier).follow(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          'Follow',
          style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
