import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/providers/api_providers.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/chat_remote_data_source.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/get_or_create_chat.dart';
import '../../domain/usecases/mark_chat_as_read.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/watch_chats.dart';
import '../../domain/usecases/watch_messages.dart';

part 'chat_providers.g.dart';

@riverpod
ChatRemoteDataSource chatRemoteDataSource(Ref ref) {
  return ApiChatRemoteDataSource(
    apiClient: ref.watch(apiClientProvider),
    socketService: ref.watch(socketServiceProvider),
  );
}

@riverpod
ChatRepository chatRepository(Ref ref) {
  return ChatRepositoryImpl(ref.watch(chatRemoteDataSourceProvider));
}

@riverpod
WatchChats watchChatsUseCase(Ref ref) => WatchChats(ref.watch(chatRepositoryProvider));

@riverpod
WatchMessages watchMessagesUseCase(Ref ref) => WatchMessages(ref.watch(chatRepositoryProvider));

@riverpod
GetOrCreateChat getOrCreateChatUseCase(Ref ref) => GetOrCreateChat(ref.watch(chatRepositoryProvider));

@riverpod
SendMessage sendMessageUseCase(Ref ref) => SendMessage(ref.watch(chatRepositoryProvider));

@riverpod
MarkChatAsRead markChatAsReadUseCase(Ref ref) => MarkChatAsRead(ref.watch(chatRepositoryProvider));

/// Chat list for the signed-in user.
@riverpod
Stream<List<ChatEntity>> myChats(Ref ref) {
  final uid = ref.watch(authStateProvider).value;
  if (uid == null) return Stream.value(const []);
  return ref.watch(watchChatsUseCaseProvider).call(uid);
}

@riverpod
Stream<List<MessageEntity>> chatMessages(Ref ref, String chatId) {
  return ref.watch(watchMessagesUseCaseProvider).call(chatId);
}

/// Resolves (creating if necessary) the chat id for a 1:1 conversation
/// with [otherUserId], so [ChatScreen] can be opened with just the other
/// person's uid even before any chat document exists.
@riverpod
Future<String> resolvedChatId(Ref ref, String otherUserId) async {
  final currentProfile = await ref.watch(currentUserProfileProvider.future);
  if (currentProfile == null) throw const AuthFailure('You must be signed in to chat.');

  final otherProfile = await ref.watch(userProfileProvider(otherUserId).future);
  if (otherProfile == null) throw const NotFoundFailure('This user could not be found.');

  final result = await ref.watch(getOrCreateChatUseCaseProvider).call(
    currentUid: currentProfile.uid,
    currentUsername: currentProfile.username,
    currentPhotoUrl: currentProfile.photoUrl,
    otherUid: otherProfile.uid,
    otherUsername: otherProfile.username,
    otherPhotoUrl: otherProfile.photoUrl,
  );

  return switch (result) {
    Ok(value: final chatId) => chatId,
    Err(failure: final failure) => throw failure,
  };
}

@riverpod
class ChatController extends _$ChatController {
  @override
  FutureOr<void> build() {}

  Future<void> sendMessage({required String chatId, required String text}) async {
    final uid = ref.read(authStateProvider).value;
    if (uid == null || text.trim().isEmpty) return;
    await ref.read(sendMessageUseCaseProvider).call(chatId: chatId, senderId: uid, text: text.trim());
  }
}
