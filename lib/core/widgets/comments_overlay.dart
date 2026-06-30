import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/comments/presentation/providers/comment_providers.dart';
import 'skeleton.dart';

/// Scrollable comment stream overlaid on a video — positioned at the bottom
/// of the Stack body so comments float over the reel while the video plays.
class CommentsOverlay extends ConsumerWidget {
  final String postId;

  const CommentsOverlay({super.key, required this.postId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentsAsync = ref.watch(commentsControllerProvider(postId));

    return Stack(
      children: [
        // Fade from transparent at top to semi-dark at bottom so text is readable.
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.65),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
        commentsAsync.when(
          data: (comments) {
            if (comments.isEmpty) return const SizedBox.shrink();
            return NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                  ref.read(commentsControllerProvider(postId).notifier).loadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 32, 72, 12),
                itemCount: comments.length,
                itemBuilder: (context, index) {
                  final c = comments[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '@${c.authorUsername}  ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                            ),
                          ),
                          TextSpan(
                            text: c.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.fromLTRB(16, 32, 72, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(
                4,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SkeletonBox(
                    width: i.isEven ? 220 : 160,
                    height: 12,
                  ),
                ),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
