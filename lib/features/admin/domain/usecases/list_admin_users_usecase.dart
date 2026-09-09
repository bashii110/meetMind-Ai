import '../entities/admin_user.dart';
import '../repositories/admin_repository.dart';

class ListAdminUsersUseCase {
  const ListAdminUsersUseCase(this._repository);

  final AdminRepository _repository;

  Future<PaginatedAdminUsers> call({String? search, int page = 1}) {
    return _repository.listUsers(search: search, page: page);
  }
}
