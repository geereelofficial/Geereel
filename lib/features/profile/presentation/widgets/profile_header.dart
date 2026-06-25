import 'package:flutter/material.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/profile_image_viewer.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity profile;
  final VoidCallback? onTapFollowers;
  final VoidCallback? onTapFollowing;

  const ProfileHeader({
    super.key,
    required this.profile,
    this.onTapFollowers,
    this.onTapFollowing,
  });

  @override
  Widget build(BuildContext context) {
    // Compact, single-row layout (avatar beside name/stats rather than
    // stacked) so the header takes a small, fixed slice of the screen and
    // the posts grid below gets most of the vertical space, TikTok-profile
    // style.
    final photoUrl = profile.photoUrl;
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: hasPhoto ? () => showProfileImageViewer(context, photoUrl) : null,
            child: AppAvatar(photoUrl: photoUrl, radius: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  profile.displayName,
                  style: AppTextStyles.heading3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@${profile.username}',
                  style: AppTextStyles.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (profile.bio.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTextStyles.body),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatColumn(label: 'Posts', value: profile.postsCount),
                    const SizedBox(width: 20),
                    _StatColumn(
                      label: 'Followers',
                      value: profile.followersCount,
                      onTap: onTapFollowers,
                    ),
                    const SizedBox(width: 20),
                    _StatColumn(
                      label: 'Following',
                      value: profile.followingCount,
                      onTap: onTapFollowing,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;
  final VoidCallback? onTap;

  const _StatColumn({required this.label, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Text(Formatters.compactCount(value), style: AppTextStyles.heading3),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
