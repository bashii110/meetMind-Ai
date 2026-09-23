import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/widgets/status_chip.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('replaces underscores and title-cases a known status', (tester) async {
    await tester.pumpWidget(wrap(const StatusChip(status: 'in_progress')));
    expect(find.text('In progress'), findsOneWidget);
  });

  testWidgets('still renders (with the outline fallback color) for an unknown status', (tester) async {
    await tester.pumpWidget(wrap(const StatusChip(status: 'mystery')));
    expect(find.text('Mystery'), findsOneWidget);
  });
}
