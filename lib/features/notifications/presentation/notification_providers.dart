import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/providers/api_providers.dart';
import '../../../core/providers/firebase_providers.dart';
import '../data/fcm_token_manager.dart';

part 'notification_providers.g.dart';

@riverpod
FcmTokenManager fcmTokenManager(Ref ref) {
  return FcmTokenManager(
    messaging: ref.watch(firebaseMessagingProvider),
    apiClient: ref.watch(apiClientProvider),
  );
}
