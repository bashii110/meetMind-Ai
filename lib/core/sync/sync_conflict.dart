import 'dart:convert';

/// A task edit made offline that the server's copy has since diverged
/// from — surfaced for the user to manually resolve, per this project's
/// "tasks use manual merge prompts" policy (meetings use last-write-wins
/// instead and never produce one of these).
class SyncConflict {
  const SyncConflict({
    required this.id,
    required this.taskId,
    required this.localChanges,
    required this.serverSnapshot,
    required this.detectedAt,
  });

  final String id;
  final String taskId;

  /// Just the fields the offline edit touched (whatever UpdateTaskUseCase
  /// was called with), not the whole task.
  final Map<String, dynamic> localChanges;

  /// The task as the server currently has it, fetched the moment the
  /// conflict is detected, so the resolution screen shows a real diff
  /// instead of a stale local copy.
  final Map<String, dynamic> serverSnapshot;
  final DateTime detectedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'local_changes': jsonEncode(localChanges),
        'server_snapshot': jsonEncode(serverSnapshot),
        'detected_at': detectedAt.toIso8601String(),
      };

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] as String,
      taskId: json['task_id'] as String,
      localChanges: Map<String, dynamic>.from(jsonDecode(json['local_changes'] as String) as Map),
      serverSnapshot: Map<String, dynamic>.from(jsonDecode(json['server_snapshot'] as String) as Map),
      detectedAt: DateTime.parse(json['detected_at'] as String),
    );
  }
}
