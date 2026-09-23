import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/widgets/priority_indicator.dart';

void main() {
  testWidgets('capitalizes the priority label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PriorityIndicator(priority: 'high'))),
    );

    expect(find.text('High'), findsOneWidget);
  });
}
