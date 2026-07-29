import 'package:dio/dio.dart';

import 'api_failure.dart';

/// Attaches the current access token (if any) to every outgoing request.
/// Token retrieval is injected so this stays decoupled from a concrete
/// storage implementation (flutter_secure_storage in practice).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readAccessToken});

  final Future<String?> Function() readAccessToken;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

/// Converts DioExceptions into the app-wide [ApiFailure] shape so
/// repositories/use cases never need to know about Dio directly.
class ErrorMappingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        ApiFailure.timeout(),
      DioExceptionType.connectionError => ApiFailure.network(),
      DioExceptionType.badResponse => _mapResponseError(err),
      _ => ApiFailure.unknown(err.message),
    };

    handler.next(err.copyWith(error: failure));
  }

  ApiFailure _mapResponseError(DioException err) {
    final status = err.response?.statusCode;
    final data = err.response?.data;

    String message = 'Something went wrong. Please try again.';
    Map<String, List<String>> fieldErrors = {};

    if (data is Map<String, dynamic>) {
      message = data['message'] as String? ?? message;
      final errors = data['errors'];
      if (errors is Map) {
        fieldErrors = errors.map(
          (key, value) => MapEntry(
            key.toString(),
            (value as List).map((e) => e.toString()).toList(),
          ),
        );
      }
    }

    if (status == 401) return ApiFailure.unauthorized();

    return ApiFailure(
      message: message,
      statusCode: status,
      fieldErrors: fieldErrors,
    );
  }
}
