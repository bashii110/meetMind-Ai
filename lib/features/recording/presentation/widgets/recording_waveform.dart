import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/recording/presentation/providers/recording_controller.dart';


/// DESIGN.md 3.5: "large waveform animation as the centerpiece." Built
/// with a plain CustomPainter fed by [RecordingController]'s amplitude
/// stream, rather than a third-party waveform-capture widget — this
/// project already gets its live audio levels from `package:record`
/// directly (see AudioRecorderDataSource.amplitudeStream), so a second
/// package's recording API isn't needed just to draw bars.
class RecordingWaveform extends ConsumerStatefulWidget {
  const RecordingWaveform({super.key});

  @override
  ConsumerState<RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends ConsumerState<RecordingWaveform> {
  static const _maxBars = 40;
  final List<double> _levels = List.filled(_maxBars, 0.05);

  @override
  Widget build(BuildContext context) {
    ref.listen<double>(recordingControllerProvider.select((s) => s.amplitude), (previous, next) {
      setState(() {
        _levels.add(next);
        if (_levels.length > _maxBars) _levels.removeAt(0);
      });
    });

    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _WaveformPainter(levels: List.of(_levels), color: scheme.primary),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({required this.levels, required this.color});

  final List<double> levels;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;

    final barWidth = size.width / levels.length;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < levels.length; i++) {
      final level = levels[i].clamp(0.05, 1.0);
      final barHeight = size.height * level;
      final rect = Rect.fromLTWH(
        i * barWidth + barWidth * 0.15,
        (size.height - barHeight) / 2,
        barWidth * 0.7,
        barHeight,
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => oldDelegate.levels != levels;
}
