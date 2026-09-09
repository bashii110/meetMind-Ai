import '../entities/moderation_item.dart';
import '../repositories/admin_repository.dart';

class ListModerationQueueUseCase {
  const ListModerationQueueUseCase(this._repository);

  final AdminRepository _repository;

  Future<PaginatedModerationItems> call({int page = 1}) => _repository.listModerationQueue(page: page);
}
