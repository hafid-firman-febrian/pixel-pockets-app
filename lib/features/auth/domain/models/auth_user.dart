/// Signed-in user — pure domain entity. No SDK (`google_sign_in`) types, so
/// the app's upper layers never depend on the auth provider.
///
/// [idToken] is the credential the API expects as a Bearer token. It is part of
/// the auth domain on purpose: keeping it here lets the Dio interceptor read it
/// synchronously from state without reaching back into the SDK.
class AuthUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? idToken;

  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.idToken,
  });
}
