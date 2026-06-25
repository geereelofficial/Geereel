import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../feed/presentation/providers/feed_providers.dart';
import 'posts_grid.dart';

/// One paginated grid of a profile's posts (uploaded/liked/reposted) —
/// loads the next page as the user scrolls near the bottom instead of
/// fetching the whole history up front, mirroring the main feed's pattern.
class ProfilePostsTabView extends ConsumerStatefulWidget {
  final String uid;
  final ProfilePostsTab tab;
  final String emptyMessage;

  const ProfilePostsTabView({
    super.key,
    required this.uid,
    required this.tab,
    required this.emptyMessage,
  });

  @override
  ConsumerState<ProfilePostsTabView> createState() => _ProfilePostsTabViewState();
}

class _ProfilePostsTabViewState extends ConsumerState<ProfilePostsTabView> {
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
      ref.read(profilePostsControllerProvider(widget.uid, widget.tab).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = profilePostsControllerProvider(widget.uid, widget.tab);
    final postsAsync = ref.watch(provider);

    return postsAsync.when(
      data: (posts) => RefreshIndicator(
        onRefresh: () => ref.read(provider.notifier).refresh(),
        child: PostsGrid(
          posts: posts,
          scrollController: _scrollController,
          emptyMessage: widget.emptyMessage,
          onTap: (post) => context.push('/profile/${widget.uid}/posts/${post.postId}?tab=${widget.tab.name}'),
        ),
      ),
      loading: () => const LoadingIndicator(),
      error: (error, _) => ErrorView(
        message: error.toString(),
        onRetry: () => ref.invalidate(provider),
      ),
    );
  }
}
