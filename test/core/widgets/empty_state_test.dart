import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/widgets/empty_state.dart';

void main() {
  testWidgets('shows the icon, title, and optional message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(icon: Icons.inbox, title: 'Nothing here', message: 'Check back later.'),
        ),
      ),
    );

    expect(find.byIcon(Icons.inbox), findsOneWidget);
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Check back later.'), findsOneWidget);
  });

  testWidgets('renders without a message when none is given', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyState(icon: Icons.inbox, title: 'Nothing here'))),
    );

    expect(find.text('Nothing here'), findsOneWidget);
  });
}
