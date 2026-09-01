import '../entities/workspace.dart';
import '../repositories/workspace_repository.dart';

class CreateWorkspaceUseCase {
  const CreateWorkspaceUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<Workspace> call({required String name, String? description}) {
    return _repository.create(name: name, description: description);
  }
}
