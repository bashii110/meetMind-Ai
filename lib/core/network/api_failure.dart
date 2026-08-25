import 'package:dio/dio.dart';

/// Normalized failure shape for every API error, regardless of whether it
/// came from a network problem, a validation error, or an HTTP status.
///
/// Backend errors follow the envelope in ARCHITECTURE.md section 5:
///   { "message": "...", "errors": { "field": ["..."] } }
class ApiFailure implements Exception {
  const ApiFailure({
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  factory ApiFailure.network() => const ApiFailure(
    message: 'Could not reach the server. Check your connection.',
  );

  factory ApiFailure.timeout() => const ApiFailure(
    message: 'The request timed out. Please try again.',
  );

  factory ApiFailure.unauthorized() => const ApiFailure(
    message: 'Your session has expired. Please sign in again.',
    statusCode: 401,
  );

  factory ApiFailure.unknown([String? message]) => ApiFailure(
    message: message ?? 'Something went wrong. Please try again.',
  );

  /// Unwraps *any* caught error into an [ApiFailure].
  ///
  /// [ErrorMappingInterceptor] attaches an [ApiFailure] to
  /// `DioException.error`, but Dio still throws the [DioException]
  /// *wrapper* to the call site — never the [ApiFailure] itself. Every
  /// catch block and every `AsyncValue.error` display must go through this
  /// factory instead of checking `error is ApiFailure` directly, otherwise
  /// that check is always false and every real failure (a validation
  /// error, "account disabled", a 403, ...) silently collapses into a
  /// generic/garbled message instead of the actual reason.
  factory ApiFailure.from(Object error) {
    if (error is ApiFailure) return error;
    if (error is DioException) {
      final wrapped = error.error;
      if (wrapped is ApiFailure) return wrapped;
      return ApiFailure.unknown(error.message);
    }
    return ApiFailure.unknown(error.toString());
  }

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}
