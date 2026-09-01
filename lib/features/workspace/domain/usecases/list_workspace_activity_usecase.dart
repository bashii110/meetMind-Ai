import '../entities/paginated_activity.dart';
import '../repositories/workspace_repository.dart';

class ListWorkspaceActivityUseCase {
  const ListWorkspaceActivityUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<PaginatedActivity> call(String workspaceId, {int page = 1}) {
    return _repository.listActivity(workspaceId, page: page);
  }
}
