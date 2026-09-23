import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/tasks/presentation/widgets/deadline_chip.dart';

void main() {
  testWidgets('shows "Overdue" when isOverdue is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DeadlineChip(deadline: DateTime(2026, 1, 1), isOverdue: true),
        ),
      ),
    );

    expect(find.textContaining('Overdue'), findsOneWidget);
  });

  testWidgets('does not say "Overdue" for a future deadline', (tester) async {
    final soon = DateTime.now().add(const Duration(days: 3));

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: DeadlineChip(deadline: soon))),
    );

    expect(find.textContaining('Overdue'), findsNothing);
  });
}
