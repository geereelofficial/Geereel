import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/formatters.dart';
import '../../domain/entities/message_entity.dart';

class MessageBubble extends StatelessWidget {
  final MessageEntity message;
  final bool isMine;

  const MessageBubble({super.key, required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    const cornerRadius = Radius.circular(18);
    const tailRadius = Radius.circular(4);

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 2,
          bottom: 2,
          left: isMine ? 48 : 12,
          right: isMine ? 12 : 48,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: cornerRadius,
            topRight: cornerRadius,
            bottomLeft: isMine ? cornerRadius : tailRadius,
            bottomRight: isMine ? tailRadius : cornerRadius,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.text, style: AppTextStyles.body),
            const SizedBox(height: 4),
            Text(
              Formatters.relativeTime(message.createdAt),
              style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary.withValues(alpha: 0.6)),
            ),
          ],
        ),
      ),
    );
  }
}
