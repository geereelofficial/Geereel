import 'package:firebase_auth/firebase_auth.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';

/// Thin wrapper over the Socket.io client used for real-time chat. Emits
/// raw JSON payloads — feature datasources are responsible for parsing
/// them into their own models, so this stays a core/infra concern with no
/// dependency on feature code.
class SocketService {
  io.Socket? _socket;
  final _messageControllers = <void Function(Map<String, dynamic>)>[];
  final _errorControllers = <void Function(Map<String, dynamic>)>[];

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    _socket?.dispose();
    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnectError((_) {});
    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        for (final listener in _messageControllers) {
          listener(data);
        }
      }
    });
    _socket!.on('chat_error', (data) {
      if (data is Map<String, dynamic>) {
        for (final listener in _errorControllers) {
          listener(data);
        }
      }
    });

    _socket!.connect();
  }

  void disconnect() {
    _socket?.disconnect();
  }

  void joinChat(String chatId) => _socket?.emit('join_chat', {'chatId': chatId});

  void leaveChat(String chatId) => _socket?.emit('leave_chat', {'chatId': chatId});

  void sendMessage({required String chatId, required String text}) {
    _socket?.emit('send_message', {'chatId': chatId, 'text': text});
  }

  void addMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageControllers.add(listener);
  }

  void removeMessageListener(void Function(Map<String, dynamic>) listener) {
    _messageControllers.remove(listener);
  }

  void addErrorListener(void Function(Map<String, dynamic>) listener) {
    _errorControllers.add(listener);
  }

  void removeErrorListener(void Function(Map<String, dynamic>) listener) {
    _errorControllers.remove(listener);
  }
}
