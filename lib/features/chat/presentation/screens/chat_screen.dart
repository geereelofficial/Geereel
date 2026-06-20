import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/message_bubble.dart';

/// 1:1 chat with [otherUserId]. Resolves/creates the underlying chat
/// document via [resolvedChatIdProvider] before showing the message list.
class ChatScreen extends ConsumerStatefulWidget {
  final String otherUserId;

  const ChatScreen({super.key, required this.otherUserId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _send(String chatId) async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;
    _textController.clear();
    await ref.read(chatControllerProvider.notifier).sendMessage(chatId: chatId, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final otherProfileAsync = ref.watch(userProfileProvider(widget.otherUserId));
    final chatIdAsync = ref.watch(resolvedChatIdProvider(widget.otherUserId));

    ref.listen(resolvedChatIdProvider(widget.otherUserId), (previous, next) {
      final chatId = next.value;
      final uid = ref.read(authStateProvider).value;
      if (chatId != null && uid != null) {
        ref.read(markChatAsReadUseCaseProvider).call(chatId: chatId, uid: uid);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            AppAvatar(photoUrl: otherProfileAsync.value?.photoUrl, radius: 16),
            const SizedBox(width: 10),
            Text('@${otherProfileAsync.value?.username ?? '...'}'),
          ],
        ),
      ),
      body: chatIdAsync.when(
        data: (chatId) => _MessageList(chatId: chatId, textController: _textController, onSend: _send),
        loading: () => const LoadingIndicator(),
        error: (error, _) => ErrorView(message: error.toString()),
      ),
    );
  }
}

class _MessageList extends ConsumerWidget {
  final String chatId;
  final TextEditingController textController;
  final Future<void> Function(String chatId) onSend;

  const _MessageList({required this.chatId, required this.textController, required this.onSend});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(chatMessagesProvider(chatId));
    final currentUid = ref.watch(authStateProvider).value;

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) {
              if (messages.isEmpty) {
                return const Center(child: Text('Say hello 👋'));
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return MessageBubble(message: message, isMine: message.senderId == currentUid);
                },
              );
            },
            loading: () => const LoadingIndicator(),
            error: (error, _) => ErrorView(
              message: error.toString(),
              onRetry: () => ref.invalidate(chatMessagesProvider(chatId)),
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(hintText: 'Message...'),
                    onSubmitted: (_) => onSend(chatId),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => onSend(chatId),
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
