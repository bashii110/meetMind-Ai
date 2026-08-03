import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/auth_controller.dart';
import '../widgets/auth_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, required this.token, required this.email});

  /// Populated from the deep link's query params
  /// (`meetmindai://reset-password?token=...&email=...`) — see
  /// backend/app/Notifications/ResetPasswordNotification.php and the
  /// GoRoute wiring in core/router/app_router.dart.
  final String token;
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _passwordConfirmation = TextEditingController();

  bool _submitting = false;
  String? _formError;

  @override
  void dispose() {
    _password.dispose();
    _passwordConfirmation.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _formError = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(
            token: widget.token,
            email: widget.email,
            password: _password.text,
            passwordConfirmation: _passwordConfirmation.text,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset. Please log in.')),
        );
        context.go(AppRoutes.login);
      }
    } catch (e) {
      final failure = e is ApiFailure ? e : ApiFailure.unknown(e.toString());
      setState(() => _formError = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set a new password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('for ${widget.email}', style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: Spacing.lg),
                  if (_formError != null) ...[
                    Text(_formError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: Spacing.md),
                  ],
                  AuthTextField(
                    label: 'New password',
                    controller: _password,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                  ),
                  const SizedBox(height: Spacing.md),
                  AuthTextField(
                    label: 'Confirm new password',
                    controller: _passwordConfirmation,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: Spacing.lg),
                  ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Reset password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
