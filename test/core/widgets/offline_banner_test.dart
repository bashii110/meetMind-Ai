import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/network/connectivity_controller.dart';
import 'package:meetmind_ai/core/widgets/offline_banner.dart';

void main() {
  Future<void> pumpWithOnline(WidgetTester tester, bool online) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [isOnlineProvider.overrideWithValue(online)],
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ),
    );
  }

  testWidgets('renders nothing while online', (tester) async {
    await pumpWithOnline(tester, true);

    expect(
      find.text("You're offline — changes will sync when you're back online."),
      findsNothing,
    );
  });

  testWidgets('shows the offline message and icon when offline', (tester) async {
    await pumpWithOnline(tester, false);

    expect(
      find.text("You're offline — changes will sync when you're back online."),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });
}
