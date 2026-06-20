import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';

/// Wraps [Dio] with a Firebase ID-token auth interceptor and maps HTTP
/// failures onto this app's [Exception] hierarchy, so datasources never
/// see Dio/HTTP types directly.
class ApiClient {
  final Dio _dio;
  final FirebaseAuth _firebaseAuth;

  ApiClient({Dio? dio, FirebaseAuth? firebaseAuth})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConstants.apiPrefix)),
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // currentUser can be null for a brief window after app launch while
          // Firebase Auth is still restoring the persisted session — wait for
          // the first auth-state emission instead of treating that as signed-out.
          var user = _firebaseAuth.currentUser;
          user ??= await _firebaseAuth.authStateChanges().first;
          final token = await user?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _run(() => _dio.get(path, queryParameters: query));
  }

  Future<Response<dynamic>> post(String path, {dynamic data}) {
    return _run(() => _dio.post(path, data: data));
  }

  Future<Response<dynamic>> patch(String path, {dynamic data}) {
    return _run(() => _dio.patch(path, data: data));
  }

  Future<Response<dynamic>> delete(String path) {
    return _run(() => _dio.delete(path));
  }

  Future<Response<dynamic>> _run(Future<Response<dynamic>> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw _mapDioException(e);
    }
  }

  Exception _mapDioException(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return const NetworkException();
    }

    final statusCode = e.response?.statusCode;
    final message = _extractMessage(e.response?.data) ?? e.message ?? 'Something went wrong.';

    switch (statusCode) {
      case 401:
      case 403:
        return AuthException(message);
      case 404:
        return NotFoundException(message);
      default:
        return ServerException(message);
    }
  }

  String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] is String) return data['message'] as String;
    return null;
  }
}
