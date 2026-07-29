import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/network/api_failure.dart';

/// Calls the backend's health-check endpoint. This is the concrete proof of
/// PHASES.md Phase 0's deliverable: "Empty but running Flutter app ↔
/// Laravel API 'ping' endpoint, version-controlled."
///
/// Once auth (Phase 1) and the real dashboard (Phase 2+, DESIGN.md 3.3)
/// land, this provider can be removed.
final pingProvider = FutureProvider.autoDispose<String>((ref) async {
  final dio = ref.watch(dioProvider);

  try {
    final response = await dio.get('/ping');
    return response.data['message'] as String? ?? 'pong';
  } on DioException catch (e) {
    // ErrorMappingInterceptor attaches an ApiFailure to `.error`.
    throw (e.error is ApiFailure) ? e.error as ApiFailure : ApiFailure.unknown(e.message);
  }
});
