import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

/// Registers/refreshes the current device's FCM token with the backend
/// (`POST /api/users/:uid/fcm-tokens`), multi-device-safe since each
/// device's token is stored separately and deduped by token value.
///
/// Infra-only for the MVP: no foreground notification UI is wired up yet
/// (no `flutter_local_notifications`), but the token pipeline is in place
/// so the backend can target these tokens once push triggers (new like/
/// comment/message) are added.
class FcmTokenManager {
  final FirebaseMessaging _messaging;
  final ApiClient _apiClient;

  FcmTokenManager({required ApiClient apiClient, FirebaseMessaging? messaging})
    : _apiClient = apiClient,
      _messaging = messaging ?? FirebaseMessaging.instance;

  Future<void> registerToken(String uid) async {
    final settings = await _messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    final token = await _messaging.getToken();
    if (token != null) await _saveToken(uid, token);

    _messaging.onTokenRefresh.listen((newToken) => _saveToken(uid, newToken));
  }

  Future<void> removeCurrentToken(String uid) async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _apiClient.delete('/users/$uid/fcm-tokens/$token');
  }

  Future<void> _saveToken(String uid, String token) async {
    await _apiClient.post(
      '/users/$uid/fcm-tokens',
      data: {'token': token, 'platform': defaultTargetPlatform.name},
    );
  }
}
