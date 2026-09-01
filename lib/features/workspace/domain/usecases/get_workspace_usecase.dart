import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class GetWorkspaceUseCase {
  const GetWorkspaceUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<Workspace> call(String id) => _repository.getById(id);
}
