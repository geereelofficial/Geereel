import 'dart:io';
import 'package:dio/dio.dart';
import '../errors/exceptions.dart';
import 'api_client.dart';

/// Uploads a file directly to Cloudinary using a signature minted by our
/// backend (`POST /api/media/signature`) — the API secret never reaches
/// this app. The backend is never in the media byte path.
class CloudinaryUploader {
  final ApiClient _apiClient;
  final Dio _dio;

  CloudinaryUploader(this._apiClient, {Dio? dio}) : _dio = dio ?? Dio();

  /// Returns the Cloudinary `secure_url` for the uploaded file.
  Future<String> upload({
    required File file,
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    Response<dynamic> signatureResponse;
    try {
      signatureResponse = await _apiClient.post('/media/signature', data: {'folder': folder});
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException('Failed to get upload signature: $e');
    }

    final Map<String, dynamic> data;
    final String cloudName;
    try {
      data = signatureResponse.data as Map<String, dynamic>;
      cloudName = data['cloudName'] as String;
    } catch (e) {
      throw StorageException('Invalid signature response from server: $e');
    }

    final FormData formData;
    try {
      formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        'api_key': data['apiKey'],
        'timestamp': data['timestamp'],
        'signature': data['signature'],
        'folder': data['folder'],
      });
    } catch (e) {
      throw StorageException('Failed to read media file: $e');
    }

    try {
      final response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$cloudName/auto/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );

      final secureUrl = (response.data as Map<String, dynamic>)['secure_url'] as String?;
      if (secureUrl == null) {
        throw const StorageException('Upload succeeded but no URL was returned.');
      }
      return secureUrl;
    } on StorageException {
      rethrow;
    } catch (e) {
      final message = e is DioException ? (e.message ?? 'Failed to upload media.') : '$e';
      throw StorageException(message);
    }
  }
}
