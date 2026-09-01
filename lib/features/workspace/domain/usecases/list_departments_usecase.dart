import '../entities/department.dart';
import '../repositories/workspace_repository.dart';

class ListDepartmentsUseCase {
  const ListDepartmentsUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<List<Department>> call(String workspaceId) => _repository.listDepartments(workspaceId);
}
