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

  @override
  String toString() => 'ApiFailure($statusCode): $message';
}
