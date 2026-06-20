import '../../../../core/utils/result.dart';
import '../repositories/chat_repository.dart';

class SendMessage {
  final ChatRepository _repository;

  const SendMessage(this._repository);

  Future<Result<void>> call({required String chatId, required String senderId, required String text}) {
    return _repository.sendMessage(chatId: chatId, senderId: senderId, text: text);
  }
}
