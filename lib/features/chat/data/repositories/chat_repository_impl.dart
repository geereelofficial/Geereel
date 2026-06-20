import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_data_source.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource _remote;

  const ChatRepositoryImpl(this._remote);

  @override
  Stream<List<ChatEntity>> watchChats(String uid) {
    return _remote.watchChats(uid).map((models) => models.map((m) => m.toEntityFor(uid)).toList());
  }

  @override
  Stream<List<MessageEntity>> watchMessages(
    String chatId, {
    int limit = AppConstants.messagesPageSize,
  }) {
    return _remote
        .watchMessages(chatId, limit: limit)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Future<Result<String>> getOrCreateChat({
    required String currentUid,
    required String currentUsername,
    String? currentPhotoUrl,
    required String otherUid,
    required String otherUsername,
    String? otherPhotoUrl,
  }) async {
    try {
      final chatId = await _remote.getOrCreateChat(
        currentUid: currentUid,
        currentUsername: currentUsername,
        currentPhotoUrl: currentPhotoUrl,
        otherUid: otherUid,
        otherUsername: otherUsername,
        otherPhotoUrl: otherPhotoUrl,
      );
      return Ok(chatId);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    try {
      await _remote.sendMessage(chatId: chatId, senderId: senderId, text: text);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  @override
  Future<Result<void>> markChatAsRead({required String chatId, required String uid}) async {
    try {
      await _remote.markChatAsRead(chatId: chatId, uid: uid);
      return const Ok(null);
    } catch (e) {
      return Err(_mapToFailure(e));
    }
  }

  Failure _mapToFailure(Object error) {
    if (error is NetworkException) return NetworkFailure(error.message);
    if (error is ServerException) return ServerFailure(error.message);
    return const UnknownFailure();
  }
}
