import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'dio_interceptors.dart';

/// Base URL per environment. Swap via --dart-define=API_BASE_URL=... at
/// build time rather than hardcoding per-flavor values here.
const _defaultBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://192.168.100.139:8000/api/v1', // Android emulator -> localhost:8000
);

/// Builds the single Dio instance the app shares. Feature data sources
/// should receive this via Riverpod (see core/di) rather than constructing
/// their own Dio, so interceptors/auth stay consistent everywhere.
Dio buildApiClient({
  required Future<String?> Function() readAccessToken,
  String baseUrl = _defaultBaseUrl,
  bool enableLogging = false,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(AuthInterceptor(readAccessToken: readAccessToken));
  dio.interceptors.add(ErrorMappingInterceptor());

  if (enableLogging) {
    dio.interceptors.add(
      PrettyDioLogger(requestBody: true, responseBody: true, error: true),
    );
  }

  return dio;
}
