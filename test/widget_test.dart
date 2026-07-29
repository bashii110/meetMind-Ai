import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meetmind_ai/main.dart';

void main() {
  testWidgets('App boots and shows the splash screen', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MeetMindApp()));
    await tester.pump();

    expect(find.text('MeetMind AI'), findsOneWidget);
  });
}
