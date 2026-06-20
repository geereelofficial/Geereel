import '../../../../core/utils/result.dart';
import '../repositories/chat_repository.dart';

class GetOrCreateChat {
  final ChatRepository _repository;

  const GetOrCreateChat(this._repository);

  Future<Result<String>> call({
    required String currentUid,
    required String currentUsername,
    String? currentPhotoUrl,
    required String otherUid,
    required String otherUsername,
    String? otherPhotoUrl,
  }) {
    return _repository.getOrCreateChat(
      currentUid: currentUid,
      currentUsername: currentUsername,
      currentPhotoUrl: currentPhotoUrl,
      otherUid: otherUid,
      otherUsername: otherUsername,
      otherPhotoUrl: otherPhotoUrl,
    );
  }
}
