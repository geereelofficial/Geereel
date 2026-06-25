import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_posts_tab_view.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String uid;

  const ProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late final bool _isOwnProfile;
  late final List<ProfilePostsTab> _tabs;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = ref.read(authStateProvider).value == widget.uid;
    // Liked/marked/shared posts are private, so only show those tabs on
    // your own profile.
    _tabs = _isOwnProfile
        ? [
            ProfilePostsTab.uploaded,
            ProfilePostsTab.liked,
            ProfilePostsTab.reposted,
            ProfilePostsTab.marked,
            ProfilePostsTab.shared,
          ]
        : [ProfilePostsTab.uploaded, ProfilePostsTab.reposted];
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _tabLabel(ProfilePostsTab tab) {
    switch (tab) {
      case ProfilePostsTab.uploaded:
        return 'Posts';
      case ProfilePostsTab.liked:
        return 'Liked';
      case ProfilePostsTab.reposted:
        return 'Reposts';
      case ProfilePostsTab.marked:
        return 'Marked';
      case ProfilePostsTab.shared:
        return 'Shared';
    }
  }

  String _emptyMessage(ProfilePostsTab tab) {
    switch (tab) {
      case ProfilePostsTab.uploaded:
        return 'No posts yet';
      case ProfilePostsTab.liked:
        return 'No liked posts yet';
      case ProfilePostsTab.reposted:
        return 'No reposts yet';
      case ProfilePostsTab.marked:
        return 'No marked posts yet';
      case ProfilePostsTab.shared:
        return 'No shared posts yet';
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider(widget.uid));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isOwnProfile ? 'My Profile' : 'Profile'),
        actions: [
          if (_isOwnProfile)
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

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    ProfileHeader(
                      profile: profile,
                      onTapFollowers: () => context.push('/profile/${widget.uid}/followers'),
                      onTapFollowing: () => context.push('/profile/${widget.uid}/following'),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        height: 36,
                        child: _isOwnProfile
                            ? OutlinedButton(
                                onPressed: () => context.push('/edit-profile'),
                                child: const Text('Edit Profile'),
                              )
                            : Row(
                                children: [
                                  Expanded(child: _FollowButton(uid: widget.uid)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => context.push('/chat/${widget.uid}'),
                                      child: const Text('Message'),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _TabBarHeader(
                  TabBar(
                    controller: _tabController,
                    // Scrollable rather than fixed: with five tabs (own
                    // profile) a fixed-width TabBar squeezes "Reposts" and
                    // "Marked" enough to clip their text.
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: _tabs.map((tab) => Tab(text: _tabLabel(tab))).toList(),
                  ),
                ),
              ),
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map(
                        (tab) => ProfilePostsTabView(
                          uid: widget.uid,
                          tab: tab,
                          emptyMessage: _emptyMessage(tab),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(userProfileProvider(widget.uid)),
        ),
      ),
    );
  }
}

class _TabBarHeader extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  const _TabBarHeader(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: AppColors.background, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarHeader oldDelegate) => oldDelegate.tabBar != tabBar;
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
