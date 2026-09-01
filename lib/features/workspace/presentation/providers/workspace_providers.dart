import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/workspace_remote_data_source.dart';
import '../../data/repositories/workspace_repository_impl.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../domain/usecases/assign_member_department_usecase.dart';
import '../../domain/usecases/create_department_usecase.dart';
import '../../domain/usecases/create_workspace_usecase.dart';
import '../../domain/usecases/delete_department_usecase.dart';
import '../../domain/usecases/delete_workspace_usecase.dart';
import '../../domain/usecases/get_workspace_usecase.dart';
import '../../domain/usecases/invite_workspace_members_usecase.dart';
import '../../domain/usecases/leave_workspace_usecase.dart';
import '../../domain/usecases/list_departments_usecase.dart';
import '../../domain/usecases/list_workspace_activity_usecase.dart';
import '../../domain/usecases/list_workspace_members_usecase.dart';
import '../../domain/usecases/list_workspaces_usecase.dart';
import '../../domain/usecases/remove_workspace_member_usecase.dart';
import '../../domain/usecases/update_department_usecase.dart';
import '../../domain/usecases/update_member_role_usecase.dart';
import '../../domain/usecases/update_workspace_usecase.dart';

final workspaceRemoteDataSourceProvider = Provider(
  (ref) => WorkspaceRemoteDataSource(ref.watch(dioProvider)),
);

final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => WorkspaceRepositoryImpl(ref.watch(workspaceRemoteDataSourceProvider)),
);

final listWorkspacesUseCaseProvider =
    Provider((ref) => ListWorkspacesUseCase(ref.watch(workspaceRepositoryProvider)));
final getWorkspaceUseCaseProvider = Provider((ref) => GetWorkspaceUseCase(ref.watch(workspaceRepositoryProvider)));
final createWorkspaceUseCaseProvider =
    Provider((ref) => CreateWorkspaceUseCase(ref.watch(workspaceRepositoryProvider)));
final updateWorkspaceUseCaseProvider =
    Provider((ref) => UpdateWorkspaceUseCase(ref.watch(workspaceRepositoryProvider)));
final deleteWorkspaceUseCaseProvider =
    Provider((ref) => DeleteWorkspaceUseCase(ref.watch(workspaceRepositoryProvider)));
final leaveWorkspaceUseCaseProvider =
    Provider((ref) => LeaveWorkspaceUseCase(ref.watch(workspaceRepositoryProvider)));

final listWorkspaceMembersUseCaseProvider =
    Provider((ref) => ListWorkspaceMembersUseCase(ref.watch(workspaceRepositoryProvider)));
final inviteWorkspaceMembersUseCaseProvider =
    Provider((ref) => InviteWorkspaceMembersUseCase(ref.watch(workspaceRepositoryProvider)));
final updateMemberRoleUseCaseProvider =
    Provider((ref) => UpdateMemberRoleUseCase(ref.watch(workspaceRepositoryProvider)));
final removeWorkspaceMemberUseCaseProvider =
    Provider((ref) => RemoveWorkspaceMemberUseCase(ref.watch(workspaceRepositoryProvider)));
final assignMemberDepartmentUseCaseProvider =
    Provider((ref) => AssignMemberDepartmentUseCase(ref.watch(workspaceRepositoryProvider)));

final listDepartmentsUseCaseProvider =
    Provider((ref) => ListDepartmentsUseCase(ref.watch(workspaceRepositoryProvider)));
final createDepartmentUseCaseProvider =
    Provider((ref) => CreateDepartmentUseCase(ref.watch(workspaceRepositoryProvider)));
final updateDepartmentUseCaseProvider =
    Provider((ref) => UpdateDepartmentUseCase(ref.watch(workspaceRepositoryProvider)));
final deleteDepartmentUseCaseProvider =
    Provider((ref) => DeleteDepartmentUseCase(ref.watch(workspaceRepositoryProvider)));

final listWorkspaceActivityUseCaseProvider =
    Provider((ref) => ListWorkspaceActivityUseCase(ref.watch(workspaceRepositoryProvider)));
