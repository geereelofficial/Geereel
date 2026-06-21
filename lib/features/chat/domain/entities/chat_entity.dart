import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_entity.freezed.dart';

/// Domain representation of a 1:1 chat, already resolved to "the other
/// person" and "unread count for me" relative to the signed-in viewer —
/// the chat list never needs to know both participants' raw data.
@freezed
abstract class ChatEntity with _$ChatEntity {
  const factory ChatEntity({
    required String chatId,
    required String otherUserId,
    required String otherUsername,
    String? otherPhotoUrl,
    String? lastMessageText,
    String? lastMessageSenderId,
    DateTime? lastMessageAt,
    @Default(0) int unreadCount,
    required DateTime createdAt,
    @Default(false) bool otherIsOnline,
    DateTime? otherLastActiveAt,
  }) = _ChatEntity;
}
