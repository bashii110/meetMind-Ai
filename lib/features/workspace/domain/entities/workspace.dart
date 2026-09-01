import 'package:equatable/equatable.dart';

/// SRD FR-10.1/10.2. Mirrors backend `workspaces` table (ARCHITECTURE.md
/// section 4), plus [myRole] — the current user's own membership role,
/// which the backend embeds per-request since it depends on who's asking
/// rather than being a property of the workspace itself.
class Workspace extends Equatable {
  const Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.myRole,
    required this.createdAt,
    this.description,
    this.memberCount = 0,
    this.departmentCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final String ownerName;

  /// owner | admin | member — see [WorkspaceRole].
  final String myRole;
  final int memberCount;
  final int departmentCount;
  final DateTime createdAt;

  bool get isOwner => myRole == 'owner';

  /// Owner or admin — the roles allowed to invite/remove members, change
  /// roles, and manage departments (SRD FR-10.2).
  bool get canManage => myRole == 'owner' || myRole == 'admin';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        ownerId,
        ownerName,
        myRole,
        memberCount,
        departmentCount,
        createdAt,
      ];
}
