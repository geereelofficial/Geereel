import 'dart:io';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/cloudinary_uploader.dart';
import '../../../feed/domain/entities/post_entity.dart';
import '../models/status_group_model.dart';
import '../models/status_model.dart';
import '../models/status_viewer_model.dart';

abstract class StatusRemoteDataSource {
  Future<List<StatusGroupModel>> fetchTray();

  Future<List<StatusModel>> fetchUserStatuses(String authorId);

  Future<String> createStatus({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  });

  Future<void> markViewed(String statusId);

  Future<List<StatusViewerModel>> fetchViewers(String statusId);

  Future<void> deleteStatus(String statusId);
}

class ApiStatusRemoteDataSource implements StatusRemoteDataSource {
  final ApiClient _apiClient;
  final CloudinaryUploader _cloudinaryUploader;

  ApiStatusRemoteDataSource({required ApiClient apiClient, required CloudinaryUploader cloudinaryUploader})
    : _apiClient = apiClient,
      _cloudinaryUploader = cloudinaryUploader;

  @override
  Future<List<StatusGroupModel>> fetchTray() async {
    final response = await _apiClient.get('/statuses');
    return (response.data as List)
        .map((json) => StatusGroupModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<StatusModel>> fetchUserStatuses(String authorId) async {
    final response = await _apiClient.get('/statuses/user/$authorId');
    return (response.data as List).map((json) => StatusModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  @override
  Future<String> createStatus({
    required File mediaFile,
    required MediaType mediaType,
    double? durationSeconds,
    int? width,
    int? height,
    void Function(double progress)? onProgress,
  }) async {
    final mediaUrl = await _cloudinaryUploader.upload(
      file: mediaFile,
      folder: 'statuses',
      onProgress: onProgress,
    );

    final response = await _apiClient.post(
      '/statuses',
      data: {
        'mediaType': mediaType.name,
        'mediaUrl': mediaUrl,
        if (durationSeconds != null) 'durationSeconds': durationSeconds,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      },
    );

    return (response.data as Map<String, dynamic>)['statusId'] as String;
  }

  @override
  Future<void> markViewed(String statusId) async {
    await _apiClient.post('/statuses/$statusId/view');
  }

  @override
  Future<List<StatusViewerModel>> fetchViewers(String statusId) async {
    final response = await _apiClient.get('/statuses/$statusId/viewers');
    return (response.data as List)
        .map((json) => StatusViewerModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> deleteStatus(String statusId) async {
    await _apiClient.delete('/statuses/$statusId');
  }
}
