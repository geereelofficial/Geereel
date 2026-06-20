import 'package:flutter/material.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/comment_entity.dart';

class CommentTile extends StatelessWidget {
  final CommentEntity comment;

  const CommentTile({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppAvatar(photoUrl: comment.authorPhotoUrl, radius: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('@${comment.authorUsername}', style: AppTextStyles.username),
                    const SizedBox(width: 8),
                    Text(Formatters.relativeTime(comment.createdAt), style: AppTextStyles.caption),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.text, style: AppTextStyles.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
