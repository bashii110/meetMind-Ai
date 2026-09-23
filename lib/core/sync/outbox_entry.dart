import 'dart:convert';

/// What kind of local entity an [OutboxEntry] mutates.
enum OutboxEntityType { meeting, task }

/// Which repository operation to replay. Scoped to the mutations a user
/// is realistically going to make offline (create/edit/delete/status) —
/// secondary actions (participant invites, comments, attachments,
/// progress, assignment) stay online-only for this phase; see
/// PHASE10_README.md's known simplifications.
enum OutboxOperation { create, update, delete, changeStatus }

/// One offline mutation waiting to be replayed against the backend —
/// ARCHITECTURE.md 2.3's "outbox pattern... replayed on reconnect."
///
/// [localId] is the id the mutation applies to *locally* — either a real
/// server id (update/delete/changeStatus on an already-synced entity) or
/// a temporary `local_<uuid>` id minted by the repository for something
/// created while offline. [baseUpdatedAt] is only set for task updates —
/// the task's `updated_at` at the moment the offline edit was made, which
/// OutboxSyncManager compares against the server's current `updated_at`
/// to detect a conflicting edit; meetings don't carry this, since they
/// use last-write-wins instead.
class OutboxEntry {
  const OutboxEntry({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.localId,
    required this.payload,
    required this.createdAt,
    this.baseUpdatedAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final OutboxEntityType entityType;
  final OutboxOperation operation;
  final String localId;

  /// Operation-specific data — e.g. the create/update body, or
  /// `{'status': 'completed'}` for a changeStatus entry.
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? baseUpdatedAt;
  final int retryCount;
  final String? lastError;

  OutboxEntry copyWith({int? retryCount, String? lastError}) {
    return OutboxEntry(
      id: id,
      entityType: entityType,
      operation: operation,
      localId: localId,
      payload: payload,
      createdAt: createdAt,
      baseUpdatedAt: baseUpdatedAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entity_type': entityType.name,
        'operation': operation.name,
        'local_id': localId,
        'payload': jsonEncode(payload),
        'created_at': createdAt.toIso8601String(),
        'base_updated_at': baseUpdatedAt?.toIso8601String(),
        'retry_count': retryCount,
        'last_error': lastError,
      };

  factory OutboxEntry.fromJson(Map<String, dynamic> json) {
    return OutboxEntry(
      id: json['id'] as String,
      entityType: OutboxEntityType.values.byName(json['entity_type'] as String),
      operation: OutboxOperation.values.byName(json['operation'] as String),
      localId: json['local_id'] as String,
      payload: Map<String, dynamic>.from(jsonDecode(json['payload'] as String) as Map),
      createdAt: DateTime.parse(json['created_at'] as String),
      baseUpdatedAt:
          json['base_updated_at'] != null ? DateTime.parse(json['base_updated_at'] as String) : null,
      retryCount: json['retry_count'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }
}
