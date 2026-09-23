import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/network/api_failure.dart';

void main() {
  group('ApiFailure.from', () {
    test('returns the same instance when already an ApiFailure', () {
      const failure = ApiFailure(message: 'Nope', statusCode: 422);
      expect(ApiFailure.from(failure), same(failure));
    });

    test('unwraps the ApiFailure attached to a DioException.error', () {
      const inner = ApiFailure(
        message: 'Validation failed',
        statusCode: 422,
        fieldErrors: {
          'email': ['is required'],
        },
      );
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tasks'),
        error: inner,
      );

      expect(ApiFailure.from(dioException), same(inner));
    });

    test('falls back to the DioException message when nothing was attached', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/tasks'),
        message: 'socket closed',
      );

      expect(ApiFailure.from(dioException).message, 'socket closed');
    });

    test('wraps any other error type using its toString()', () {
      final result = ApiFailure.from(StateError('boom'));
      expect(result.message, contains('boom'));
    });
  });

  test('unauthorized() carries a 401 status code', () {
    expect(ApiFailure.unauthorized().statusCode, 401);
  });

  test('unknown() falls back to a generic message when none is given', () {
    expect(ApiFailure.unknown().message, isNotEmpty);
  });
}
