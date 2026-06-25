import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Followers/following list for a profile, loading the next page as the
/// user scrolls near the bottom rather than fetching the whole list at once.
class FollowListScreen extends ConsumerStatefulWidget {
  final String uid;
  final FollowListKind kind;

  const FollowListScreen({super.key, required this.uid, required this.kind});

  @override
  ConsumerState<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends ConsumerState<FollowListScreen> {
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
      ref.read(followListControllerProvider(widget.uid, widget.kind).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = followListControllerProvider(widget.uid, widget.kind);
    final usersAsync = ref.watch(provider);
    final title = widget.kind == FollowListKind.followers ? 'Followers' : 'Following';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(
              child: Text(
                widget.kind == FollowListKind.followers
                    ? 'No followers yet.'
                    : 'Not following anyone yet.',
                style: AppTextStyles.bodySecondary,
              ),
            );
          }
          return ListView.separated(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) => _UserTile(user: users[index]),
          );
        },
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(
          message: error.toString(),
          onRetry: () => ref.invalidate(provider),
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserEntity user;

  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AppAvatar(photoUrl: user.photoUrl, radius: 22),
      title: Text(user.displayName, style: AppTextStyles.username, overflow: TextOverflow.ellipsis),
      subtitle: Text('@${user.username}', style: AppTextStyles.bodySecondary, overflow: TextOverflow.ellipsis),
      onTap: () => context.push('/profile/${user.uid}'),
    );
  }
}
