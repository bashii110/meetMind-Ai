import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/sync/outbox_entry.dart';
import '../../../../core/sync/outbox_local_data_source.dart';
import '../../domain/entities/meeting.dart';
import '../../domain/entities/meeting_filters.dart';
import '../../domain/entities/paginated_meetings.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_local_data_source.dart';
import '../datasources/meeting_remote_data_source.dart';
import '../models/meeting_model.dart';

const _uuid = Uuid();

/// Phase 10 (ARCHITECTURE.md 2.3): cache-first reads, outbox-queued
/// writes when offline. [isOnline] is a fast pre-check to skip a doomed
/// request, not the only signal — a `DioExceptionType.connectionError`
/// from an optimistically-attempted call falls back to the same offline
/// path regardless of what it returned.
///
/// Participant invites/removal/RSVPs stay online-only for this phase —
/// see PHASE10_README.md's known simplifications.
class MeetingRepositoryImpl implements MeetingRepository {
  MeetingRepositoryImpl(
    this._remote, {
    MeetingLocalDataSource? local,
    OutboxLocalDataSource? outbox,
    bool Function()? isOnline,
  })  : _local = local ?? MeetingLocalDataSource(),
        _outbox = outbox ?? OutboxLocalDataSource(),
        _isOnline = isOnline ?? (() => true);

  final MeetingRemoteDataSource _remote;
  final MeetingLocalDataSource _local;
  final OutboxLocalDataSource _outbox;
  final bool Function() _isOnline;

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  bool _isConnectionError(Object e) => e is DioException && e.type == DioExceptionType.connectionError;

  @override
  Future<PaginatedMeetings> list({MeetingFilters filters = MeetingFilters.empty, int page = 1}) async {
    try {
      final result = await _remote.list(filters.toQueryParameters(), page);
      if (page == 1) await _local.saveAll(result.items);
      return result;
    } catch (e) {
      if (!_isConnectionError(e) && _isOnline()) rethrow;
      // Offline fallback: the cache has no pagination/filtering of its
      // own, so this returns everything cached as a single unpaginated
      // page — enough to keep the list screen usable, not a full filter
      // engine (filters are dropped, not silently mis-applied).
      final cached = _local.getAll();
      return PaginatedMeetings(items: cached, currentPage: 1, lastPage: 1, total: cached.length);
    }
  }

  @override
  Future<Meeting> getById(String id) async {
    try {
      final meeting = await _remote.getById(id);
      await _local.save(meeting);
      return meeting;
    } catch (e) {
      final cached = _local.getById(id);
      if (cached != null && (_isConnectionError(e) || !_isOnline())) return cached;
      rethrow;
    }
  }

  @override
  Future<Meeting> create({
    required String title,
    String? description,
    required DateTime date,
    String? time,
    String? location,
    String? onlineLink,
    String priority = 'medium',
    String? category,
    List<String> tags = const [],
    List<String> participantEmails = const [],
    String? workspaceId,
  }) async {
    final body = {
      if (workspaceId != null) 'workspace_id': int.tryParse(workspaceId) ?? workspaceId,
      'title': title,
      if (description != null) 'description': description,
      'date': _formatDate(date),
      if (time != null) 'time': time,
      if (location != null) 'location': location,
      if (onlineLink != null) 'online_link': onlineLink,
      'priority': priority,
      if (category != null) 'category': category,
      if (tags.isNotEmpty) 'tags': tags,
      if (participantEmails.isNotEmpty) 'participant_emails': participantEmails,
    };

    if (_isOnline()) {
      try {
        final created = await _remote.create(body);
        await _local.save(created);
        return created;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }

    // Offline: mint a temporary id so the meeting can be shown/edited
    // right away; OutboxSyncManager swaps it for the server's real id
    // once the queued create replays.
    final localId = 'local_${_uuid.v4()}';
    final localMeeting = MeetingModel(
      id: localId,
      workspaceId: workspaceId ?? '',
      title: title,
      description: description,
      date: date,
      time: time,
      location: location,
      onlineLink: onlineLink,
      priority: priority,
      category: category,
      status: 'draft',
      tags: tags,
    );
    await _local.save(localMeeting);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.meeting,
      operation: OutboxOperation.create,
      localId: localId,
      payload: body,
      createdAt: DateTime.now(),
    ));
    return localMeeting;
  }

  @override
  Future<Meeting> update(
    String id, {
    String? title,
    String? description,
    DateTime? date,
    String? time,
    String? location,
    String? onlineLink,
    String? priority,
    String? category,
    List<String>? tags,
  }) async {
    final body = {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (date != null) 'date': _formatDate(date),
      if (time != null) 'time': time,
      if (location != null) 'location': location,
      if (onlineLink != null) 'online_link': onlineLink,
      if (priority != null) 'priority': priority,
      if (category != null) 'category': category,
      if (tags != null) 'tags': tags,
    };

    if (_isOnline()) {
      try {
        final updated = await _remote.update(id, body);
        await _local.save(updated);
        return updated;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }

    final cached = _local.getById(id);
    final patched = MeetingModel(
      id: id,
      workspaceId: cached?.workspaceId ?? '',
      title: title ?? cached?.title ?? '',
      description: description ?? cached?.description,
      date: date ?? cached?.date ?? DateTime.now(),
      time: time ?? cached?.time,
      location: location ?? cached?.location,
      onlineLink: onlineLink ?? cached?.onlineLink,
      priority: priority ?? cached?.priority ?? 'medium',
      category: category ?? cached?.category,
      status: cached?.status ?? 'draft',
      ownerId: cached?.ownerId,
      ownerName: cached?.ownerName,
      tags: tags ?? cached?.tags ?? const [],
      participants: cached?.participants ?? const [],
      participantCount: cached?.participantCount ?? 0,
    );
    await _local.save(patched);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.meeting,
      operation: OutboxOperation.update,
      localId: id,
      payload: body,
      createdAt: DateTime.now(),
    ));
    return patched;
  }

  @override
  Future<void> delete(String id) async {
    if (_isOnline()) {
      try {
        await _remote.delete(id);
        await _local.delete(id);
        return;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }
    await _local.delete(id);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.meeting,
      operation: OutboxOperation.delete,
      localId: id,
      payload: const {},
      createdAt: DateTime.now(),
    ));
  }

  @override
  Future<Meeting> changeStatus(String id, String status) async {
    if (_isOnline()) {
      try {
        final updated = await _remote.changeStatus(id, status);
        await _local.save(updated);
        return updated;
      } catch (e) {
        if (!_isConnectionError(e)) rethrow;
      }
    }
    final cached = _local.getById(id);
    final patched = MeetingModel(
      id: id,
      workspaceId: cached?.workspaceId ?? '',
      title: cached?.title ?? '',
      description: cached?.description,
      date: cached?.date ?? DateTime.now(),
      time: cached?.time,
      location: cached?.location,
      onlineLink: cached?.onlineLink,
      priority: cached?.priority ?? 'medium',
      category: cached?.category,
      status: status,
      ownerId: cached?.ownerId,
      ownerName: cached?.ownerName,
      tags: cached?.tags ?? const [],
      participants: cached?.participants ?? const [],
      participantCount: cached?.participantCount ?? 0,
    );
    await _local.save(patched);
    await _outbox.add(OutboxEntry(
      id: _uuid.v4(),
      entityType: OutboxEntityType.meeting,
      operation: OutboxOperation.changeStatus,
      localId: id,
      payload: {'status': status},
      createdAt: DateTime.now(),
    ));
    return patched;
  }

  @override
  Future<List<String>> inviteParticipants(String meetingId, List<String> emails) {
    return _remote.inviteParticipants(meetingId, emails);
  }

  @override
  Future<void> removeParticipant(String meetingId, String userId) {
    return _remote.removeParticipant(meetingId, userId);
  }

  @override
  Future<void> respondToInvitation(String meetingId, String status) {
    return _remote.respondToInvitation(meetingId, status);
  }
}
