import 'package:google_sign_in/google_sign_in.dart';

/// Wraps the native Google Sign-In flow for FR-1.2.
///
/// google_sign_in v7 rewrote this API: `GoogleSignIn.instance` is a
/// singleton that must be initialized once, `authenticate()` handles the
/// interactive sign-in, and the access token is fetched *separately* via
/// `authorizationClient.authorizeScopes()` rather than being part of the
/// authentication result. See:
/// https://pub.dev/documentation/google_sign_in/latest/
///
/// `clientId`/`serverClientId` come from the Google Cloud Console — see
/// frontend/README.md's "Google Sign-In setup" section. This class only
/// covers sign-in; MeetMind's own session (Sanctum tokens) is independent
/// of the Google session once we have the access token, so there's no
/// corresponding "sign out of Google" call in the logout flow.
class GoogleAuthDataSource {
  GoogleAuthDataSource({this.clientId, this.serverClientId});

  final String? clientId;
  final String? serverClientId;

  static const _scopes = <String>['email', 'profile'];

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;

    await GoogleSignIn.instance.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );
    _initialized = true;
  }

  /// Runs the interactive sign-in flow and returns a Google **access
  /// token** for `POST /api/v1/auth/google` (verified server-side via
  /// Socialite's `userFromToken`, not an ID-token audience check, so a
  /// plain OAuth access token with the `email`/`profile` scopes is enough).
  ///
  /// Throws [GoogleSignInException] (e.g. `.canceled`) if the user
  /// dismisses the sign-in sheet — callers should catch this alongside
  /// [ApiFailure] from the subsequent backend call.
  Future<String> signInAndGetAccessToken() async {
    await _ensureInitialized();

    final account = await GoogleSignIn.instance.authenticate();
    final authorization = await account.authorizationClient.authorizeScopes(_scopes);

    return authorization.accessToken;
  }
}
