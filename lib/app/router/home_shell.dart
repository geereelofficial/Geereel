import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/navigation_providers.dart';
import '../../features/feed/presentation/providers/feed_providers.dart';
import '../../features/notifications/presentation/providers/notification_providers.dart';
import '../theme/app_colors.dart';

/// Bottom navigation shell for the four persistent tabs (Feed, Chat,
/// Notifications, Profile). "Upload" sits visually between Chat and
/// Notifications but isn't a stateful branch — tapping it pushes /upload as
/// a one-off screen instead of switching tabs, matching TikTok's center "+"
/// button.
class HomeShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> with RouteAware {
  static const _branchForVisualIndex = {0: 0, 1: 1, 3: 2, 4: 3};
  static const _visualIndexForBranch = {0: 0, 1: 1, 2: 3, 3: 4};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // A top-level screen (profile, post detail, chat, search, ...) was
  // pushed on top of the shell's own root-level route.
  @override
  void didPushNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(isShellCoveredProvider.notifier).set(true);
    });
  }

  // That screen was popped, so the shell is visible again.
  @override
  void didPopNext() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(isShellCoveredProvider.notifier).set(false);
    });
  }

  void _onTap(BuildContext context, int visualIndex) {
    if (visualIndex == 2) {
      context.push('/upload');
      return;
    }
    final branchIndex = _branchForVisualIndex[visualIndex]!;
    widget.navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  Widget _notificationsIcon(WidgetRef ref) {
    final count = ref.watch(unreadNotificationCountProvider).value ?? 0;
    return Badge(
      label: Text('$count'),
      isLabelVisible: count > 0,
      child: const Icon(Icons.notifications),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentVisualIndex = _visualIndexForBranch[widget.navigationShell.currentIndex] ?? 0;

    // Deferred to a post-frame callback because this runs during HomeShell's
    // own build, and Riverpod disallows mutating a different provider's
    // state mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedTabActiveProvider.notifier).set(widget.navigationShell.currentIndex == 0);
    });

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentVisualIndex,
        onTap: (index) => _onTap(context, index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1A1A1A),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white60,
        iconSize: 28,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_rounded),
            label: 'Inbox',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_rounded, color: AppColors.primary, size: 36),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: _notificationsIcon(ref),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
