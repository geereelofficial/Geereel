import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationTile extends StatelessWidget {
  final NotificationEntity notification;

  const NotificationTile({super.key, required this.notification});

  String get _actionText {
    switch (notification.type) {
      case NotificationType.follow:
        return 'started following you';
      case NotificationType.like:
        return 'liked your post';
      case NotificationType.comment:
        return 'commented on your post';
      case NotificationType.repost:
        return 'reposted your post';
    }
  }

  IconData get _badgeIcon {
    switch (notification.type) {
      case NotificationType.follow:
        return Icons.person_add;
      case NotificationType.like:
        return Icons.favorite;
      case NotificationType.comment:
        return Icons.mode_comment;
      case NotificationType.repost:
        return Icons.repeat;
    }
  }

  Color get _badgeColor {
    switch (notification.type) {
      case NotificationType.follow:
        return AppColors.secondary;
      case NotificationType.like:
        return AppColors.primary;
      case NotificationType.comment:
        return AppColors.surfaceVariant;
      case NotificationType.repost:
        return AppColors.secondary;
    }
  }

  void _onTap(BuildContext context) {
    if (notification.type == NotificationType.follow) {
      context.push('/profile/${notification.actorId}');
    } else if (notification.postId != null) {
      context.push('/post/${notification.postId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => _onTap(context),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(photoUrl: notification.actorPhotoUrl, radius: 22),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Icon(_badgeIcon, color: Colors.white, size: 11),
            ),
          ),
        ],
      ),
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '@${notification.actorUsername} ', style: AppTextStyles.username),
            TextSpan(text: _actionText, style: AppTextStyles.body),
          ],
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(Formatters.relativeTime(notification.createdAt), style: AppTextStyles.caption),
      trailing: notification.type == NotificationType.follow
          ? _FollowBackButton(uid: notification.actorId, seedIsFollowing: notification.isFollowingActor)
          : null,
    );
  }
}

/// Compact follow/following button for a follow notification, seeded from
/// the notification payload's [seedIsFollowing] (no extra fetch needed on
/// first paint) but backed by the same [isFollowingProvider]/
/// [followControllerProvider] the profile screen uses, so toggling here
/// stays in sync with the rest of the app.
class _FollowBackButton extends ConsumerWidget {
  final String uid;
  final bool? seedIsFollowing;

  const _FollowBackButton({required this.uid, required this.seedIsFollowing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(uid));
    final isLoading = ref.watch(followControllerProvider).isLoading;
    final isFollowing = isFollowingAsync.value ?? seedIsFollowing ?? false;

    void toggle() {
      final notifier = ref.read(followControllerProvider.notifier);
      if (isFollowing) {
        notifier.unfollow(uid);
      } else {
        notifier.follow(uid);
      }
    }

    if (isFollowing) {
      return OutlinedButton(
        onPressed: isLoading ? null : toggle,
        child: const Text('Following'),
      );
    }

    return ElevatedButton(
      onPressed: isLoading ? null : toggle,
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      child: const Text('Follow back'),
    );
  }
}
