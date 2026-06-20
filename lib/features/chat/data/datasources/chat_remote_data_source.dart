import 'dart:async';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/socket_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';

abstract class ChatRemoteDataSource {
  Stream<List<ChatModel>> watchChats(String uid);

  Stream<List<MessageModel>> watchMessages(String chatId, {required int limit});

  Future<String> getOrCreateChat({
    required String currentUid,
    required String currentUsername,
    String? currentPhotoUrl,
    required String otherUid,
    required String otherUsername,
    String? otherPhotoUrl,
  });

  Future<void> sendMessage({required String chatId, required String senderId, required String text});

  Future<void> markChatAsRead({required String chatId, required String uid});
}

/// Chats/messages are seeded from REST and kept live by listening to the
/// backend's Socket.io `new_message` broadcasts (see [SocketService]) —
/// chat is the one feature that keeps true real-time after the Firestore
/// migration; everything else became one-shot REST + refetch-on-mutation.
class ApiChatRemoteDataSource implements ChatRemoteDataSource {
  final ApiClient _apiClient;
  final SocketService _socketService;

  ApiChatRemoteDataSource({required ApiClient apiClient, required SocketService socketService})
    : _apiClient = apiClient,
      _socketService = socketService;

  @override
  Stream<List<ChatModel>> watchChats(String uid) {
    late StreamController<List<ChatModel>> controller;
    void Function(Map<String, dynamic>)? listener;

    Future<void> refresh() async {
      try {
        final chats = await _fetchChats();
        if (!controller.isClosed) controller.add(chats);
      } catch (e, st) {
        if (!controller.isClosed) controller.addError(e, st);
      }
    }

    controller = StreamController<List<ChatModel>>(
      onListen: () async {
        await _socketService.connect();
        listener = (_) => refresh();
        _socketService.addMessageListener(listener!);
        await refresh();
      },
      onCancel: () {
        if (listener != null) _socketService.removeMessageListener(listener!);
      },
    );

    return controller.stream;
  }

  Future<List<ChatModel>> _fetchChats() async {
    final response = await _apiClient.get('/chats');
    return (response.data as List).map((json) => ChatModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Stream<List<MessageModel>> watchMessages(String chatId, {required int limit}) {
    late StreamController<List<MessageModel>> controller;
    void Function(Map<String, dynamic>)? listener;
    List<MessageModel> current = [];

    controller = StreamController<List<MessageModel>>(
      onListen: () async {
        await _socketService.connect();
        _socketService.joinChat(chatId);

        listener = (data) {
          if (data['chatId'] != chatId) return;
          current = [MessageModel.fromJson(data), ...current];
          if (!controller.isClosed) controller.add(current);
        };
        _socketService.addMessageListener(listener!);

        try {
          current = await _fetchMessages(chatId, limit: limit);
          if (!controller.isClosed) controller.add(current);
        } catch (e, st) {
          if (!controller.isClosed) controller.addError(e, st);
        }
      },
      onCancel: () {
        _socketService.leaveChat(chatId);
        if (listener != null) _socketService.removeMessageListener(listener!);
      },
    );

    return controller.stream;
  }

  Future<List<MessageModel>> _fetchMessages(String chatId, {required int limit}) async {
    final response = await _apiClient.get('/chats/$chatId/messages', query: {'limit': limit});
    return (response.data as List)
        .map((json) => MessageModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String> getOrCreateChat({
    required String currentUid,
    required String currentUsername,
    String? currentPhotoUrl,
    required String otherUid,
    required String otherUsername,
    String? otherPhotoUrl,
  }) async {
    final response = await _apiClient.post('/chats', data: {'otherUid': otherUid});
    return (response.data as Map<String, dynamic>)['chatId'] as String;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    await _socketService.connect();
    _socketService.sendMessage(chatId: chatId, text: text);
  }

  @override
  Future<void> markChatAsRead({required String chatId, required String uid}) async {
    await _apiClient.post('/chats/$chatId/read');
  }
}
