import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import '../../../ai_summary/presentation/providers/ai_summary_providers.dart';

/// Polls `GET /meetings/{id}/ai-status` every 4s while the pipeline is
/// still running (anything short of summarized/failed/no_recording), and
/// stops automatically once it reaches a terminal state — DESIGN.md 3.6:
/// "Non-intrusive... badge update," not a blocking modal, so this is a
/// quiet background poll rather than something the user has to wait on.
///
/// autoDispose: polling only matters while the meeting details screen
/// (which is what watches this) is open — `ref.onDispose` cancels the
/// timer the moment nothing needs it anymore, so navigating away never
/// leaves a poll loop running.
class AiStatusController extends AutoDisposeFamilyAsyncNotifier<AiStatus, String> {
  Timer? _pollTimer;

  @override
  Future<AiStatus> build(String meetingId) async {
    ref.onDispose(() => _pollTimer?.cancel());

    final status = await ref.read(getAiStatusUseCaseProvider)(meetingId);
    if (!_isTerminal(status.status)) {
      _scheduleNextPoll();
    }
    return status;
  }

  /// Manual refresh — e.g. a pull-to-refresh on one of the AI tabs.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(getAiStatusUseCaseProvider)(arg));

    final value = state.valueOrNull;
    if (value != null && !_isTerminal(value.status)) {
      _scheduleNextPoll();
    }
  }

  void _scheduleNextPoll() {
    _pollTimer?.cancel();
    _pollTimer = Timer(const Duration(seconds: 4), _poll);
  }

  Future<void> _poll() async {
    try {
      final next = await ref.read(getAiStatusUseCaseProvider)(arg);
      state = AsyncData(next);
      if (!_isTerminal(next.status)) {
        _scheduleNextPoll();
      }
    } catch (_) {
      // A transient poll failure (e.g. a dropped connection) shouldn't
      // flip the whole tab into an error state for a background refresh
      // the user didn't initiate — just try again on the next tick.
      _scheduleNextPoll();
    }
  }

  bool _isTerminal(AiPipelineStatus status) =>
      status == AiPipelineStatus.summarized ||
      status == AiPipelineStatus.failed ||
      status == AiPipelineStatus.noRecording;
}

final aiStatusControllerProvider =
    AsyncNotifierProvider.autoDispose.family<AiStatusController, AiStatus, String>(AiStatusController.new);
