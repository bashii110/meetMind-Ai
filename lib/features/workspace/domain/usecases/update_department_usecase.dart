import '../entities/department.dart';
import '../repositories/workspace_repository.dart';

class UpdateDepartmentUseCase {
  const UpdateDepartmentUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<Department> call(String workspaceId, String departmentId, String name) {
    return _repository.updateDepartment(workspaceId, departmentId, name);
  }
}
