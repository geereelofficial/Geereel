import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../comments/presentation/widgets/comment_bottom_sheet.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';

/// Right-hand column of the feed, mirroring TikTok: author avatar (with a
/// quick-follow "+" badge) on top, then like/comment/bookmark/share below.
class FeedActionButtons extends ConsumerWidget {
  final PostEntity post;

  const FeedActionButtons({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeProvider = likeControllerProvider(post.postId, post.likesCount, post.liked);
    final (isLiked, likeCount) = ref.watch(likeProvider);

    final bookmarkProvider = bookmarkControllerProvider(post.postId, post.bookmarksCount, post.bookmarked);
    final (isBookmarked, bookmarkCount) = ref.watch(bookmarkProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AuthorAvatar(post: post),
        const SizedBox(height: 22),
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          filled: isLiked,
          fillColor: AppColors.primary,
          label: Formatters.compactCount(likeCount),
          onTap: () => ref.read(likeProvider.notifier).toggle(),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.mode_comment,
          label: Formatters.compactCount(post.commentsCount),
          onTap: () => showCommentBottomSheet(context, postId: post.postId),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          filled: isBookmarked,
          fillColor: AppColors.warning,
          label: Formatters.compactCount(bookmarkCount),
          onTap: () => ref.read(bookmarkProvider.notifier).toggle(),
        ),
        const SizedBox(height: 18),
        _ActionButton(
          icon: Icons.reply,
          label: Formatters.compactCount(post.sharesCount),
          onTap: () => _onShare(context, ref),
        ),
      ],
    );
  }

  Future<void> _onShare(BuildContext context, WidgetRef ref) async {
    ref.read(postRepositoryProvider).incrementShareCount(post.postId);

    final text = post.caption.isNotEmpty
        ? '${post.caption}\n\nWatch on Geereel — @${post.authorUsername}\n${post.mediaUrl}'
        : 'Check out this video by @${post.authorUsername} on Geereel:\n${post.mediaUrl}';

    await SharePlus.instance.share(ShareParams(text: text));
  }
}

/// Author avatar with a TikTok-style "+" quick-follow badge. The badge is
/// hidden for your own posts and disappears once you already follow the
/// author.
class _AuthorAvatar extends ConsumerWidget {
  final PostEntity post;

  const _AuthorAvatar({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myUid = ref.watch(authStateProvider).value;
    final isOwnPost = myUid == null || myUid == post.authorId;
    final followProvider = feedFollowControllerProvider(post.authorId, post.isFollowingAuthor);
    final isFollowing = isOwnPost ? true : ref.watch(followProvider);

    return GestureDetector(
      onTap: () => context.push('/profile/${post.authorId}'),
      child: SizedBox(
        width: 48,
        height: 58,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AppAvatar(photoUrl: post.authorPhotoUrl, radius: 24),
            if (!isOwnPost && !isFollowing)
              Positioned(
                bottom: -4,
                child: GestureDetector(
                  onTap: () => ref.read(followProvider.notifier).follow(),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A like/comment/bookmark/share button: an icon inside a filled circular
/// badge with a count label below, matching the Follow/Repost buttons'
/// solid-color style. [filled] switches the badge from a neutral translucent
/// backdrop to [fillColor] once the action is active (liked/bookmarked).
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final Color fillColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.filled = false,
    this.fillColor = AppColors.surfaceVariant,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? fillColor : Colors.black.withValues(alpha: 0.35),
            ),
            child: Icon(icon, color: Colors.white, size: 23),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
