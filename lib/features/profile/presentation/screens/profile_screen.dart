import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../widgets/posts_grid.dart';
import '../widgets/profile_header.dart';

class ProfileScreen extends ConsumerWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUid = ref.watch(authStateProvider).value;
    final isOwnProfile = currentUid == uid;
    final profileAsync = ref.watch(userProfileProvider(uid));
    final postsAsync = ref.watch(userPostsProvider(uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(isOwnProfile ? 'My Profile' : 'Profile'),
        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const ErrorView(message: 'This profile could not be found.');
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(userPostsProvider(uid)),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                ProfileHeader(profile: profile),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: isOwnProfile
                      ? OutlinedButton(
                          onPressed: () => context.push('/edit-profile'),
                          child: const Text('Edit Profile'),
                        )
                      : Row(
                          children: [
                            Expanded(child: _FollowButton(uid: uid)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => context.push('/chat/$uid'),
                                child: const Text('Message'),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 16),
                postsAsync.when(
                  data: (posts) => PostsGrid(posts: posts),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: LoadingIndicator(),
                  ),
                  error: (error, _) => ErrorView(message: error.toString()),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
      ),
    );
  }
}

class _FollowButton extends ConsumerWidget {
  final String uid;

  const _FollowButton({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFollowingAsync = ref.watch(isFollowingProvider(uid));
    final isLoading = ref.watch(followControllerProvider).isLoading;
    final isFollowing = isFollowingAsync.value ?? false;

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
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      child: const Text('Follow'),
    );
  }
}
