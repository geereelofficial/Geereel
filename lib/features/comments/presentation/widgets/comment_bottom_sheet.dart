import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/comment_providers.dart';
import 'comment_tile.dart';

/// Opens the comment list + composer for [postId] as a draggable bottom
/// sheet, mirroring TikTok's comment drawer.
void showCommentBottomSheet(
  BuildContext context, {
  required String postId,
  required int initialCommentCount,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _CommentSheet(postId: postId, initialCommentCount: initialCommentCount),
  );
}

class _CommentSheet extends ConsumerStatefulWidget {
  final String postId;
  final int initialCommentCount;

  const _CommentSheet({required this.postId, required this.initialCommentCount});

  @override
  ConsumerState<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends ConsumerState<_CommentSheet> {
  final _textController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final profile = ref.read(currentUserProfileProvider).value;
    if (profile == null) return;

    setState(() => _isPosting = true);
    final result = await ref.read(addCommentUseCaseProvider).call(
      postId: widget.postId,
      authorId: profile.uid,
      authorUsername: profile.username,
      authorPhotoUrl: profile.photoUrl,
      text: text,
    );

    if (!mounted) return;
    setState(() => _isPosting = false);

    switch (result) {
      case Ok(value: final comment):
        ref.read(commentsControllerProvider(widget.postId).notifier).prependLocal(comment);
        ref
            .read(commentCountControllerProvider(widget.postId, widget.initialCommentCount).notifier)
            .increment();
        _textController.clear();
      case Err():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not post your comment. Please try again.')),
        );
    }
  }

  void _onScroll(ScrollMetrics metrics) {
    if (metrics.pixels >= metrics.maxScrollExtent - 300) {
      ref.read(commentsControllerProvider(widget.postId).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsControllerProvider(widget.postId));

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Comments', style: AppTextStyles.heading3),
            const Divider(height: 24),
            Expanded(
              child: commentsAsync.when(
                data: (comments) {
                  if (comments.isEmpty) {
                    return const Center(
                      child: Text('No comments yet. Be the first!', style: AppTextStyles.bodySecondary),
                    );
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      _onScroll(notification.metrics);
                      return false;
                    },
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: comments.length,
                      itemBuilder: (context, index) => CommentTile(comment: comments[index]),
                    ),
                  );
                },
                loading: () => const LoadingIndicator(),
                error: (error, _) => ErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(commentsControllerProvider(widget.postId)),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        maxLength: AppConstants.maxCaptionLength,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _isPosting ? null : _submit,
                      icon: const Icon(Icons.send, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
