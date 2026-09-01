import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class ListWorkspacesUseCase {
  const ListWorkspacesUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<List<Workspace>> call() => _repository.list();
}
