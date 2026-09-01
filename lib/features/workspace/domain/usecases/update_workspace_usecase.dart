import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class UpdateWorkspaceUseCase {
  const UpdateWorkspaceUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<Workspace> call(String id, {String? name, String? description}) {
    return _repository.update(id, name: name, description: description);
  }
}
