import '../entities/platform_stats.dart';
import '../repositories/admin_repository.dart';

class GetPlatformStatsUseCase {
  const GetPlatformStatsUseCase(this._repository);

  final AdminRepository _repository;

  Future<PlatformStats> call() => _repository.getPlatformStats();
}
