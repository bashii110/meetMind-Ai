import 'package:equatable/equatable.dart';

/// PHASES.md Phase 7: "Departments grouping (optional sub-structure
/// within workspace)." Purely organizational — a department is a named
/// grouping of workspace members, not a separate permission boundary
/// (permissions live at the [WorkspaceRole] level).
class Department extends Equatable {
  const Department({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.memberCount = 0,
  });

  final String id;
  final String workspaceId;
  final String name;
  final int memberCount;

  @override
  List<Object?> get props => [id, workspaceId, name, memberCount];
}
