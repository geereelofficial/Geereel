import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/result.dart';
import '../entities/chat_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  /// Live, most-recently-active-first list of [uid]'s chats.
  Stream<List<ChatEntity>> watchChats(String uid);

  /// Live, newest-first message list for [chatId].
  Stream<List<MessageEntity>> watchMessages(String chatId, {int limit = AppConstants.messagesPageSize});

  /// Returns the deterministic chat id for this pair, creating the chat
  /// document on first contact.
  Future<Result<String>> getOrCreateChat({
    required String currentUid,
    required String currentUsername,
    String? currentPhotoUrl,
    required String otherUid,
    required String otherUsername,
    String? otherPhotoUrl,
  });

  Future<Result<void>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  });

  Future<Result<void>> markChatAsRead({required String chatId, required String uid});
}
