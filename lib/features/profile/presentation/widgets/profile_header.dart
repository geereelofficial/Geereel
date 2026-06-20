import 'package:flutter/material.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/domain/entities/user_entity.dart';

class ProfileHeader extends StatelessWidget {
  final UserEntity profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(photoUrl: profile.photoUrl, radius: 44),
        const SizedBox(height: 12),
        Text(profile.displayName, style: AppTextStyles.heading3),
        Text('@${profile.username}', style: AppTextStyles.bodySecondary),
        if (profile.bio.isNotEmpty) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(profile.bio, textAlign: TextAlign.center, style: AppTextStyles.body),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatColumn(label: 'Posts', value: profile.postsCount),
            const SizedBox(width: 32),
            _StatColumn(label: 'Followers', value: profile.followersCount),
            const SizedBox(width: 32),
            _StatColumn(label: 'Following', value: profile.followingCount),
          ],
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final int value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(Formatters.compactCount(value), style: AppTextStyles.heading3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
