import '../repositories/workspace_repository.dart';

class DeleteDepartmentUseCase {
  const DeleteDepartmentUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<void> call(String workspaceId, String departmentId) {
    return _repository.deleteDepartment(workspaceId, departmentId);
  }
}
