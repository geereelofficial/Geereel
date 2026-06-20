import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_entity.freezed.dart';

enum MessageType { text }

/// Domain representation of a single chat message. [MessageType] is an
/// enum of one today so adding image/video messages later is a new enum
/// value, not a schema change.
@freezed
abstract class MessageEntity with _$MessageEntity {
  const factory MessageEntity({
    required String messageId,
    required String chatId,
    required String senderId,
    required String text,
    @Default(MessageType.text) MessageType type,
    required DateTime createdAt,
  }) = _MessageEntity;
}
