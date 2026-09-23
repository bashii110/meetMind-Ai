import '../../features/meetings/domain/entities/meeting_summary.dart';

/// A lightweight, fully client-side "AI Meeting Score" (PHASES.md Phase
/// 12's bonus-feature list) — computed heuristically from the
/// already-generated [MeetingSummary] rather than a second OpenAI call,
/// since there's no backend endpoint for this. Rewards meetings that
/// produced clear outcomes (decisions, next steps, deadlines) and treats
/// a surfaced risk as a good sign (it was named, not swept under the
/// rug), weighted first by the AI's own mood read.
class MeetingScore {
  const MeetingScore({required this.value, required this.factors});

  /// 0-100.
  final int value;

  /// Short, human-readable reasons behind the score, in the order they
  /// were evaluated — shown in an expandable sheet in the UI.
  final List<String> factors;

  String get label {
    if (value >= 80) return 'Excellent';
    if (value >= 60) return 'Good';
    if (value >= 40) return 'Fair';
    return 'Needs follow-up';
  }

  factory MeetingScore.fromSummary(MeetingSummary summary) {
    var value = 0;
    final factors = <String>[];

    switch (summary.mood) {
      case MeetingMood.positive:
        value += 30;
        factors.add('Positive overall tone (+30)');
        break;
      case MeetingMood.neutral:
        value += 15;
        factors.add('Neutral overall tone (+15)');
        break;
      case MeetingMood.tense:
        factors.add('Tense overall tone (+0)');
        break;
    }

    if (summary.decisions.isNotEmpty) {
      value += 20;
      factors.add(
        '${summary.decisions.length} decision${summary.decisions.length == 1 ? '' : 's'} recorded (+20)',
      );
    }

    if (summary.nextSteps.isNotEmpty) {
      value += 20;
      factors.add(
        '${summary.nextSteps.length} next step${summary.nextSteps.length == 1 ? '' : 's'} identified (+20)',
      );
    }

    if (summary.deadlines.isNotEmpty) {
      value += 20;
      factors.add('${summary.deadlines.length} deadline${summary.deadlines.length == 1 ? '' : 's'} set (+20)');
    }

    if (summary.risks.isNotEmpty) {
      value += 10;
      factors.add(
        '${summary.risks.length} risk${summary.risks.length == 1 ? '' : 's'} surfaced, not overlooked (+10)',
      );
    }

    return MeetingScore(value: value.clamp(0, 100), factors: factors);
  }
}
