import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../domain/entities/chat_entity.dart';

/// One row in the chat inbox: avatar with a TikTok/WhatsApp-style online
/// dot, bold preview text while unread, and a compact unread-count pill.
/// Purely presentational — every value it needs (including
/// [isLastMessageMine]) is resolved by the caller, so this stays O(1) per
/// tile with no provider watches of its own.
class ChatListTile extends StatelessWidget {
  final ChatEntity chat;
  final bool isLastMessageMine;
  final VoidCallback onTap;
  final VoidCallback onTapAvatar;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.isLastMessageMine,
    required this.onTap,
    required this.onTapAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;
    final preview = switch (chat.lastMessageText) {
      null => 'Say hello 👋',
      final text when isLastMessageMine => 'You: $text',
      final text => text,
    };

    return ListTile(
      onTap: onTap,
      tileColor: hasUnread ? AppColors.primary.withValues(alpha: 0.06) : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      // A separate tap target from the row itself, so tapping the photo
      // opens that person's profile while tapping the rest of the row
      // (username, preview, timestamp) opens the chat as usual.
      leading: GestureDetector(
        onTap: onTapAvatar,
        behavior: HitTestBehavior.opaque,
        child: _AvatarWithPresence(photoUrl: chat.otherPhotoUrl, isOnline: chat.otherIsOnline),
      ),
      title: Text(
        '@${chat.otherUsername}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.username,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySecondary.copyWith(
            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chat.lastMessageAt != null)
            Text(
              Formatters.relativeTime(chat.lastMessageAt!),
              style: AppTextStyles.caption.copyWith(
                color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          const SizedBox(height: 8),
          if (hasUnread)
            IntrinsicWidth(
              child: Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  Formatters.compactCount(chat.unreadCount),
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}

/// Avatar with a small filled-circle badge bottom-right when [isOnline],
/// matching the online indicator in TikTok's/WhatsApp's DM inbox.
class _AvatarWithPresence extends StatelessWidget {
  final String? photoUrl;
  final bool isOnline;

  const _AvatarWithPresence({required this.photoUrl, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppAvatar(photoUrl: photoUrl, radius: 26),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
