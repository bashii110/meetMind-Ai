import 'package:flutter/material.dart';
import 'package:meetmind_ai/core/network/api_failure.dart';


/// Runs [action] and, if it throws, surfaces the real reason via a
/// SnackBar instead of letting the failure disappear silently. Meant for
/// button callbacks that fire an unawaited Future from `onPressed` (a
/// status change, an invite response, a task confirm/dismiss...) — an
/// unhandled error there never reaches the user otherwise; it just looks
/// like the tap did nothing.
Future<void> runOrNotify(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ApiFailure.from(e).message)),
      );
    }
  }
}
