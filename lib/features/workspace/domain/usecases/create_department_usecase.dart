import '../entities/department.dart';
import '../repositories/workspace_repository.dart';

class CreateDepartmentUseCase {
  const CreateDepartmentUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<Department> call(String workspaceId, String name) => _repository.createDepartment(workspaceId, name);
}
