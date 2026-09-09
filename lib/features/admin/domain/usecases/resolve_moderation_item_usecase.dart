import '../repositories/admin_repository.dart';

class ResolveModerationItemUseCase {
  const ResolveModerationItemUseCase(this._repository);

  final AdminRepository _repository;

  Future<void> call(String itemId, {required bool remove}) {
    return _repository.resolveModerationItem(itemId, remove: remove);
  }
}
