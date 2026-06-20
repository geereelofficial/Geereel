import '../entities/chat_entity.dart';
import '../repositories/chat_repository.dart';

class WatchChats {
  final ChatRepository _repository;

  const WatchChats(this._repository);

  Stream<List<ChatEntity>> call(String uid) => _repository.watchChats(uid);
}
