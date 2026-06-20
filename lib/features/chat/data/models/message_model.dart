import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../core/utils/timestamp_converter.dart';
import '../../domain/entities/message_entity.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String messageId,
    required String chatId,
    required String senderId,
    required String text,
    @Default(MessageType.text) MessageType type,
    @TimestampConverter() required DateTime createdAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
}

extension MessageModelMapper on MessageModel {
  MessageEntity toEntity() => MessageEntity(
    messageId: messageId,
    chatId: chatId,
    senderId: senderId,
    text: text,
    type: type,
    createdAt: createdAt,
  );
}
