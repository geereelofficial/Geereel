import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/status_entity.dart';
import '../providers/status_providers.dart';

/// Horizontal row of status avatars above the feed: a gradient ring for
/// unviewed statuses, a plain ring once everything from that author has
/// been seen, and "Your status" first with a quick-add "+" badge — same
/// shape as Instagram/TikTok/WhatsApp's status tray.
class StatusTray extends ConsumerWidget {
  const StatusTray({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trayAsync = ref.watch(statusTrayProvider);
    final myUid = ref.watch(authStateProvider).value;

    return trayAsync.when(
      data: (groups) {
        StatusGroupEntity? myGroup;
        final otherGroups = <StatusGroupEntity>[];
        for (final group in groups) {
          if (group.authorId == myUid) {
            myGroup = group;
          } else {
            otherGroups.add(group);
          }
        }

        return SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _MyStatusAvatar(group: myGroup),
              for (final group in otherGroups) _StatusAvatar(group: group),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (_, _) => SizedBox(
        height: 100,
        child: Center(
          child: GestureDetector(
            onTap: () => ref.invalidate(statusTrayProvider),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text('Retry', style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MyStatusAvatar extends ConsumerWidget {
  final StatusGroupEntity? group;

  const _MyStatusAvatar({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasStatus = group != null && group!.statuses.isNotEmpty;
    // Always show the signed-in user's own profile photo here (not just
    // when they have an active status), so "Your status" doubles as the
    // home page's profile-photo affordance, matching how the profile
    // screen's own avatar looks.
    final myPhotoUrl = ref.watch(currentUserProfileProvider).value?.photoUrl;

    return _TrayItem(
      label: 'Your status',
      photoUrl: myPhotoUrl,
      ring: hasStatus
          ? (group!.hasUnviewed ? _Ring.gradient : _Ring.muted)
          : _Ring.none,
      badge: GestureDetector(
        onTap: () => context.push('/status/create'),
        child: const _AddBadge(),
      ),
      onTap: () {
        if (hasStatus) {
          context.push('/status/${group!.authorId}');
        } else {
          context.push('/status/create');
        }
      },
    );
  }
}

class _StatusAvatar extends StatelessWidget {
  final StatusGroupEntity group;

  const _StatusAvatar({required this.group});

  @override
  Widget build(BuildContext context) {
    return _TrayItem(
      label: '@${group.authorUsername}',
      photoUrl: group.authorPhotoUrl,
      ring: group.hasUnviewed ? _Ring.gradient : _Ring.muted,
      onTap: () => context.push('/status/${group.authorId}'),
    );
  }
}

enum _Ring { gradient, muted, none }

class _TrayItem extends StatelessWidget {
  final String label;
  final String? photoUrl;
  final _Ring ring;
  final Widget? badge;
  final VoidCallback onTap;

  const _TrayItem({
    required this.label,
    required this.photoUrl,
    required this.ring,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 68,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  padding: const EdgeInsets.all(2.5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ring == _Ring.gradient ? AppColors.primaryGradient : null,
                    border: ring == _Ring.muted
                        ? Border.all(color: AppColors.textDisabled, width: 2)
                        : ring == _Ring.none
                        ? Border.all(color: AppColors.surfaceVariant, width: 2)
                        : null,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.background),
                    child: AppAvatar(photoUrl: photoUrl, radius: 25),
                  ),
                ),
                if (badge != null) Positioned(right: -2, bottom: -2, child: badge!),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddBadge extends StatelessWidget {
  const _AddBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary,
        border: Border.all(color: AppColors.background, width: 2),
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 14),
    );
  }
}
