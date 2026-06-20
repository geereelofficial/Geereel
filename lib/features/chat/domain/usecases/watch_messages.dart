import '../../../../core/constants/app_constants.dart';
import '../entities/message_entity.dart';
import '../repositories/chat_repository.dart';

class WatchMessages {
  final ChatRepository _repository;

  const WatchMessages(this._repository);

  Stream<List<MessageEntity>> call(String chatId, {int limit = AppConstants.messagesPageSize}) {
    return _repository.watchMessages(chatId, limit: limit);
  }
}
