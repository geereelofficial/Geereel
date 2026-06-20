import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/chat_entity.dart';

class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final VoidCallback onTap;

  const ChatListTile({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;

    return ListTile(
      onTap: onTap,
      leading: AppAvatar(photoUrl: chat.otherPhotoUrl, radius: 24),
      title: Text('@${chat.otherUsername}', style: AppTextStyles.username),
      subtitle: Text(
        chat.lastMessageText ?? 'Say hello 👋',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySecondary.copyWith(
          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chat.lastMessageAt != null)
            Text(Formatters.relativeTime(chat.lastMessageAt!), style: AppTextStyles.caption),
          if (hasUnread) ...[
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.primary,
              child: Text(
                '${chat.unreadCount}',
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
