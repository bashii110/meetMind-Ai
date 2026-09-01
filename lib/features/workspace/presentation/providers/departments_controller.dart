import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/department.dart';
import 'workspace_providers.dart';

class DepartmentsController extends AutoDisposeFamilyAsyncNotifier<List<Department>, String> {
  @override
  Future<List<Department>> build(String arg) => ref.read(listDepartmentsUseCaseProvider)(arg);

  Future<void> create(String name) async {
    await ref.read(createDepartmentUseCaseProvider)(arg, name);
    await _reload();
  }

  Future<void> updateProfile(String departmentId, String name) async {
    await ref.read(updateDepartmentUseCaseProvider)(arg, departmentId, name);
    await _reload();
  }

  Future<void> delete(String departmentId) async {
    await ref.read(deleteDepartmentUseCaseProvider)(arg, departmentId);
    await _reload();
  }

  /// Public alias for pull-to-refresh.
  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(listDepartmentsUseCaseProvider)(arg));
  }
}

final departmentsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<DepartmentsController, List<Department>, String>(DepartmentsController.new);
