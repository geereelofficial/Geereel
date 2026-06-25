/// Backend REST/Socket.io endpoint configuration.
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://geereel-backend.onrender.com',
  );

  static const String apiPrefix = '$baseUrl/api';
}
