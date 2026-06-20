import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../comments/presentation/widgets/comment_bottom_sheet.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';

/// Right-hand column of action buttons (like/comment/share) plus the
/// author avatar, mirroring TikTok's feed layout.
class FeedActionButtons extends ConsumerWidget {
  final PostEntity post;

  const FeedActionButtons({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLikedAsync = ref.watch(isPostLikedProvider(post.postId));
    final isLiked = isLikedAsync.value ?? false;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppAvatar(radius: 24),
        const SizedBox(height: 24),
        _ActionButton(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          iconColor: isLiked ? AppColors.primary : AppColors.textPrimary,
          label: Formatters.compactCount(post.likesCount),
          onTap: () => ref.read(feedControllerProvider.notifier).toggleLike(post.postId),
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.mode_comment,
          label: Formatters.compactCount(post.commentsCount),
          onTap: () => showCommentBottomSheet(context, postId: post.postId),
        ),
        const SizedBox(height: 20),
        _ActionButton(
          icon: Icons.reply,
          label: Formatters.compactCount(post.sharesCount),
          onTap: () => _onShare(context, ref),
        ),
      ],
    );
  }

  // MVP share action: just registers the share count. Swap in a real share
  // sheet (e.g. `share_plus`) without touching the rest of the feed.
  void _onShare(BuildContext context, WidgetRef ref) {
    ref.read(postRepositoryProvider).incrementShareCount(post.postId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied (placeholder) — wire up share_plus here.')),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.iconColor = AppColors.textPrimary,
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
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
