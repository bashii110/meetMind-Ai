import '../repositories/workspace_repository.dart';

class LeaveWorkspaceUseCase {
  const LeaveWorkspaceUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<void> call(String id) => _repository.leave(id);
}
