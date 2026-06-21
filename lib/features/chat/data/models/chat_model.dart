import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/chat_entity.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

/// Data-layer shape of a `/api/chats` chat document. Kept close to the
/// raw document shape (nested maps) rather than the viewer-relative
/// [ChatEntity], since both participants share one doc.
@freezed
abstract class ChatModel with _$ChatModel {
  const factory ChatModel({
    required String chatId,
    required List<String> participantIds,
    required Map<String, dynamic> participantInfo,
    Map<String, dynamic>? lastMessage,
    @Default(<String, dynamic>{}) Map<String, dynamic> unreadCount,
    @TimestampConverter() required DateTime createdAt,
    @Default(<String, dynamic>{}) Map<String, dynamic> presence,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(json);
}

extension ChatModelMapper on ChatModel {
  ChatEntity toEntityFor(String viewerUid) {
    final otherUid = participantIds.firstWhere(
      (id) => id != viewerUid,
      orElse: () => viewerUid,
    );
    final otherInfo = participantInfo[otherUid] as Map<String, dynamic>?;
    final lastMsg = lastMessage;
    final rawUnread = unreadCount[viewerUid];
    final otherPresence = presence[otherUid] as Map<String, dynamic>?;

    return ChatEntity(
      chatId: chatId,
      otherUserId: otherUid,
      otherUsername: otherInfo?['username'] as String? ?? '',
      otherPhotoUrl: otherInfo?['photoUrl'] as String?,
      lastMessageText: lastMsg?['text'] as String?,
      lastMessageSenderId: lastMsg?['senderId'] as String?,
      lastMessageAt: lastMsg?['createdAt'] == null
          ? null
          : const TimestampConverter().fromJson(lastMsg!['createdAt']),
      unreadCount: rawUnread is int ? rawUnread : 0,
      createdAt: createdAt,
      otherIsOnline: otherPresence?['online'] as bool? ?? false,
      otherLastActiveAt: const NullableTimestampConverter().fromJson(otherPresence?['lastActiveAt']),
    );
  }
}
