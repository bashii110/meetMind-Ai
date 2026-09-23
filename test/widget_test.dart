import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meetmind_ai/features/auth/presentation/screens/splash_screen.dart';

/// Phase 11 note: the previous version of this test pumped the full
/// [MeetMindApp]. Since Phase 10, that triggers `connectivity_plus`,
/// `flutter_secure_storage`, and a live Dio request on startup (via
/// `_startupSyncProvider` / `AuthController.build()`) — none of which
/// have platform-channel mocks available under a plain `flutter test`
/// run, so that version could hang or throw depending on the
/// environment, and as far as this project's records show it was never
/// actually run to confirm it passed.
///
/// A true full-app boot test belongs in `integration_test/`, where those
/// channels are mockable end-to-end. This stays a fast, deterministic
/// smoke test of what the app actually shows first — SplashScreen is a
/// ConsumerWidget that doesn't read any provider in build(), so it needs
/// nothing overridden.
void main() {
  testWidgets('Splash screen renders the app name and tagline', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SplashScreen()),
      ),
    );

    expect(find.text('MeetMind AI'), findsOneWidget);
    expect(find.text('Meetings, summarized. Tasks, tracked.'), findsOneWidget);
  });
}
