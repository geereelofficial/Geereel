import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/post_entity.dart';
import '../providers/feed_providers.dart';

/// Opens the repost action sheet for [post], mirroring the repost/quote
/// choice from Twitter/X: not-yet-reposted posts offer a plain "Repost"
/// (instant, no message) and a "Quote" (repost with your own thoughts
/// attached); an already-reposted post just offers "Undo Repost".
void showRepostOptionsSheet(BuildContext context, PostEntity post) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => _RepostOptionsSheet(post: post),
  );
}

class _RepostOptionsSheet extends ConsumerWidget {
  final PostEntity post;

  const _RepostOptionsSheet({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repostProvider = repostControllerProvider(post.postId, post.repostsCount, post.reposted);
    final (isReposted, _) = ref.watch(repostProvider);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 8),
          if (isReposted)
            _SheetAction(
              icon: Icons.repeat,
              label: 'Undo Repost',
              onTap: () {
                Navigator.of(context).pop();
                ref.read(repostProvider.notifier).undoRepost();
              },
            )
          else ...[
            _SheetAction(
              icon: Icons.repeat,
              label: 'Repost',
              subtitle: 'Repost this to your profile',
              onTap: () {
                Navigator.of(context).pop();
                ref.read(repostProvider.notifier).repost();
              },
            ),
            _SheetAction(
              icon: Icons.edit_outlined,
              label: 'Quote',
              subtitle: 'Add your thoughts before reposting',
              onTap: () {
                Navigator.of(context).pop();
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  builder: (context) => _QuoteComposerSheet(post: post),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600)),
      subtitle: subtitle != null ? Text(subtitle!, style: AppTextStyles.bodySecondary) : null,
      onTap: onTap,
    );
  }
}

/// Composer for a quote-repost's message, opened from the "Quote" option
/// above. Submitting calls the same [RepostController.repost] used for a
/// plain repost, just with [comment] attached.
class _QuoteComposerSheet extends ConsumerStatefulWidget {
  final PostEntity post;

  const _QuoteComposerSheet({required this.post});

  @override
  ConsumerState<_QuoteComposerSheet> createState() => _QuoteComposerSheetState();
}

class _QuoteComposerSheetState extends ConsumerState<_QuoteComposerSheet> {
  final _textController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isPosting = true);

    final repostProvider = repostControllerProvider(
      widget.post.postId,
      widget.post.repostsCount,
      widget.post.reposted,
    );
    await ref.read(repostProvider.notifier).repost(comment: _textController.text.trim());

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const Text('Quote', style: AppTextStyles.heading3),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: TextField(
                controller: _textController,
                autofocus: true,
                maxLines: 4,
                maxLength: AppConstants.maxCaptionLength,
                decoration: const InputDecoration(
                  hintText: 'Add your thoughts...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Repost'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
