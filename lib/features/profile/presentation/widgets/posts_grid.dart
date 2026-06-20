import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../feed/domain/entities/post_entity.dart';

/// 3-column grid of a user's posts, TikTok-profile style.
class PostsGrid extends StatelessWidget {
  final List<PostEntity> posts;
  final void Function(PostEntity post)? onTap;

  const PostsGrid({super.key, required this.posts, this.onTap});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: Text('No posts yet', style: TextStyle(color: AppColors.textSecondary))),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
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
