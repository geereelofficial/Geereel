import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../network/api_client.dart';
import '../network/cloudinary_uploader.dart';
import '../network/socket_service.dart';

part 'api_providers.g.dart';

@riverpod
ApiClient apiClient(Ref ref) => ApiClient();

@riverpod
CloudinaryUploader cloudinaryUploader(Ref ref) => CloudinaryUploader(ref.watch(apiClientProvider));

@riverpod
SocketService socketService(Ref ref) => SocketService();
