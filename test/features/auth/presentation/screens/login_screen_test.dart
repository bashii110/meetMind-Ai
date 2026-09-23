import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/network/api_failure.dart';
import 'package:meetmind_ai/features/auth/domain/entities/app_user.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';
import 'package:meetmind_ai/features/auth/presentation/screens/login_screen.dart';

/// Overrides just the one method the screen actually calls — everything
/// else falls through to the real AuthController, but nothing else is
/// exercised by this test, so nothing else needs a working Dio/secure
/// storage stack.
class _ThrowingAuthController extends AuthController {
  @override
  Future<AppUser?> build() async => null;

  @override
  Future<void> login({required String email, required String password}) async {
    throw const ApiFailure(message: 'Invalid email or password.', statusCode: 401);
  }
}

void main() {
  testWidgets('shows the failure message returned by the controller', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => _ThrowingAuthController())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'user@example.com');
    await tester.enterText(find.byType(TextField).last, 'wrong-password');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log in'));
    await tester.pumpAndSettle();

    expect(find.text('Invalid email or password.'), findsOneWidget);
  });

  testWidgets('renders the email and password fields plus a Google sign-in option', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(() => _ThrowingAuthController())],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
