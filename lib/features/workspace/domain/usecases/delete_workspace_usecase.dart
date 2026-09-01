import '../repositories/workspace_repository.dart';

class DeleteWorkspaceUseCase {
  const DeleteWorkspaceUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<void> call(String id) => _repository.delete(id);
}
