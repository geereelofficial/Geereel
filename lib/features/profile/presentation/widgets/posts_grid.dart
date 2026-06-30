import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../feed/domain/entities/post_entity.dart';

/// Returns the best available thumbnail URL for a post.
/// For Cloudinary videos, the `.jpg` variant of the video URL is a
/// server-generated still frame — no extra upload needed.
String? _resolveThumb(PostEntity post) {
  final thumb = post.thumbnailUrl;
  if (thumb != null && thumb.isNotEmpty) return thumb;
  if (post.mediaType == MediaType.image) return post.mediaUrl;
  // Cloudinary: replace extension with .jpg to get the auto-generated poster frame.
  final url = post.mediaUrl;
  if (url.contains('cloudinary.com') && url.contains('/video/upload/')) {
    final dot = url.lastIndexOf('.');
    if (dot != -1) return '${url.substring(0, dot)}.jpg';
  }
  return null;
}

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
        final imageUrl = _resolveThumb(post);

        return GestureDetector(
          onTap: onTap == null ? null : () => onTap!(post),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl != null)
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (_, __) => const ColoredBox(color: AppColors.surface),
                  errorWidget: (_, __, ___) => const ColoredBox(color: AppColors.surface),
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
                    ),
                  ),
                ),
              if (post.mediaType == MediaType.video) ...[
                // Gradient so play icon is always readable.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black54],
                      stops: [0.4, 1.0],
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(color: Colors.white70, width: 1.5),
                    ),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
