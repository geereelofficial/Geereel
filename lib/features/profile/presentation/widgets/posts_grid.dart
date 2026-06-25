import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../feed/domain/entities/post_entity.dart';

/// 3-column grid of a user's posts, TikTok-profile style.
///
/// Scrolls on its own (rather than `shrinkWrap`ping inside an outer
/// scrollable) so a profile tab can independently paginate as the user
/// scrolls it — see `ProfilePostsTabView`.
class PostsGrid extends StatelessWidget {
  final List<PostEntity> posts;
  final void Function(PostEntity post)? onTap;
  final ScrollController? scrollController;
  final String emptyMessage;

  const PostsGrid({
    super.key,
    required this.posts,
    this.onTap,
    this.scrollController,
    this.emptyMessage = 'No posts yet',
  });

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      // A scrollable (rather than a bare Center) so a RefreshIndicator
      // wrapping this widget can still detect the pull-to-refresh gesture
      // when the tab has no posts yet.
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Center(child: Text(emptyMessage, style: const TextStyle(color: AppColors.textSecondary))),
          ),
        ],
      );
    }

    return GridView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 9 / 16,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final thumbnailUrl = post.thumbnailUrl;
        final imageUrl = thumbnailUrl != null && thumbnailUrl.isNotEmpty
            ? thumbnailUrl
            : (post.mediaType == MediaType.image ? post.mediaUrl : null);

        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: AppColors.surface,
                child: imageUrl == null
                    ? const Icon(Icons.videocam, color: AppColors.textSecondary)
                    : CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
              ),
              if (post.mediaType == MediaType.video)
                const Positioned(
                  left: 4,
                  bottom: 4,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
                ),
            ],
          ),
        );
      },
    );
  }
}
