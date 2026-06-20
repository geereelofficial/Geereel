import '../../../../core/utils/result.dart';
import '../repositories/chat_repository.dart';

class MarkChatAsRead {
  final ChatRepository _repository;

  const MarkChatAsRead(this._repository);

  Future<Result<void>> call({required String chatId, required String uid}) {
    return _repository.markChatAsRead(chatId: chatId, uid: uid);
  }
}
