import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

/// Wraps flutter_secure_storage token access. Feature repositories should
/// depend on this instead of instantiating TokenStorage themselves.
final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// The single shared Dio instance. Every feature's remote data source
/// should take this via constructor injection, e.g.:
///
///   final authRemoteDataSourceProvider = Provider(
///     (ref) => AuthRemoteDataSource(ref.watch(dioProvider)),
///   );
final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  return buildApiClient(
    readAccessToken: tokenStorage.readAccessToken,
    enableLogging: !const bool.fromEnvironment('dart.vm.product'),
  );
});
