import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/notification_entity.dart';
import '../providers/notification_providers.dart';
import '../widgets/notification_tile.dart';

/// The "All / Follows / Likes / Comments / Reposts" tabs over a paginated
/// notification feed — same scrollable-TabBar + per-tab-pagination pattern
/// as the profile screen's post tabs.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  static const _filters = <NotificationFilter>[
    null,
    NotificationType.follow,
    NotificationType.like,
    NotificationType.comment,
    NotificationType.repost,
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    // Opening the screen is the read receipt — mirrors every major app's
    // notification tab (badge clears once you've looked, not once you've
    // tapped each item).
    Future.microtask(() => ref.read(markNotificationsReadControllerProvider.notifier).call());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _label(NotificationFilter filter) {
    switch (filter) {
      case null:
        return 'All';
      case NotificationType.follow:
        return 'Follows';
      case NotificationType.like:
        return 'Likes';
      case NotificationType.comment:
        return 'Comments';
      case NotificationType.repost:
        return 'Reposts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _filters.map((f) => Tab(text: _label(f))).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _filters.map((f) => _NotificationList(filter: f)).toList(),
      ),
    );
  }
}

class _NotificationList extends ConsumerStatefulWidget {
  final NotificationFilter filter;

  const _NotificationList({required this.filter});

  @override
  ConsumerState<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends ConsumerState<_NotificationList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(notificationsControllerProvider(widget.filter).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = notificationsControllerProvider(widget.filter);
    final notificationsAsync = ref.watch(provider);

    return notificationsAsync.when(
      data: (notifications) {
        if (notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => ref.read(provider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Text('Nothing here yet', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(provider.notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) => NotificationTile(notification: notifications[index]),
          ),
        );
      },
      loading: () => const ListSkeletonLoader(),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
    );
  }
}
