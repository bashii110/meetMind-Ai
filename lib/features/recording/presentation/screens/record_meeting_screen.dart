import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:meetmind_ai/features/recording/presentation/providers/recording_controller.dart';
import 'package:meetmind_ai/features/recording/presentation/widgets/recording_waveform.dart';
import '../../../../../../core/theme/spacing.dart';

String _formatDuration(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) return '${two(hours)}:${two(minutes)}:${two(seconds)}';
  return '${two(minutes)}:${two(seconds)}';
}

class RecordMeetingScreen extends ConsumerStatefulWidget {
  const RecordMeetingScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<RecordMeetingScreen> createState() => _RecordMeetingScreenState();
}

class _RecordMeetingScreenState extends ConsumerState<RecordMeetingScreen> {
  bool _finishing = false;

  Future<void> _start() async {
    await ref.read(recordingControllerProvider.notifier).start();
    if (!mounted) return;
    final error = ref.read(recordingControllerProvider).errorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _stop() async {
    setState(() => _finishing = true);

    final pending =
        await ref.read(recordingControllerProvider.notifier).stopAndUpload(widget.meetingId);

    if (!mounted) return;
    setState(() => _finishing = false);

    if (pending != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording saved — uploading in the background.')),
      );
      context.pop();
    } else {
      final error = ref.read(recordingControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Could not save the recording.')),
      );
    }
  }

  Future<void> _cancel() async {
    final phase = ref.read(recordingControllerProvider).phase;

    if (phase == RecordingPhase.idle) {
      context.pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard recording?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep recording')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Discard')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(recordingControllerProvider.notifier).cancel();
      if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingControllerProvider);
    final scheme = Theme.of(context).colorScheme;
    final isIdle = state.phase == RecordingPhase.idle;

    return PopScope(
      canPop: isIdle,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isIdle) _cancel();
      },
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          title: const Text('Record meeting'),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Column(
              children: [
                const Spacer(),
                if (isIdle) ...[
                  Icon(Icons.mic_none_rounded, size: 96, color: scheme.primary),
                  const SizedBox(height: Spacing.lg),
                  Text('Ready to record', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Once you stop, upload continues in the background — you can navigate away safely.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  const RecordingWaveform(),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    _formatDuration(state.elapsed),
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    state.phase == RecordingPhase.paused ? 'Paused' : 'Recording…',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: state.phase == RecordingPhase.paused ? scheme.outline : scheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
                const Spacer(),
                if (state.errorMessage != null && isIdle)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: scheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                _Controls(
                  phase: state.phase,
                  finishing: _finishing,
                  onStart: _start,
                  onPause: () => ref.read(recordingControllerProvider.notifier).pause(),
                  onResume: () => ref.read(recordingControllerProvider.notifier).resume(),
                  onStop: _stop,
                ),
                const SizedBox(height: Spacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.phase,
    required this.finishing,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onStop,
  });

  final RecordingPhase phase;
  final bool finishing;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (phase == RecordingPhase.idle) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.fiber_manual_record),
          label: const Text('Start recording'),
          style: ElevatedButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      );
    }

    final isStopping = phase == RecordingPhase.stopping || finishing;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _RoundButton(
          icon: phase == RecordingPhase.paused ? Icons.play_arrow : Icons.pause,
          label: phase == RecordingPhase.paused ? 'Resume' : 'Pause',
          onPressed: isStopping ? null : (phase == RecordingPhase.paused ? onResume : onPause),
        ),
        _RoundButton(
          icon: Icons.stop,
          label: 'Stop',
          filled: true,
          color: scheme.error,
          loading: isStopping,
          onPressed: isStopping ? null : onStop,
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.filled = false,
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: filled
              ? FilledButton(
                  onPressed: onPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: resolvedColor,
                    shape: const CircleBorder(),
                  ),
                  child: loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(icon, size: 32),
                )
              : OutlinedButton(
                  onPressed: onPressed,
                  style: OutlinedButton.styleFrom(
                    shape: const CircleBorder(),
                    side: BorderSide(color: resolvedColor),
                  ),
                  child: Icon(icon, size: 28, color: resolvedColor),
                ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(label, style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
