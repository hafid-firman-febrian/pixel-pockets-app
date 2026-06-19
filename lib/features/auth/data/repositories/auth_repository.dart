import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';

/// Auth data-layer gateway. Maps the `google_sign_in` SDK types into the pure
/// [AuthUser] domain model and SDK errors into [Failure], so higher layers
/// never see the SDK. The raw ID token (a [String]) is the one exception — it
/// is a credential, not domain data, and is passed through for the interceptor.
class AuthRepository {
  AuthRepository(this._remote);

  final AuthRemoteDataSource _remote;

  /// Sign-in / sign-out events as domain users (`null` == signed out).
  Stream<AuthUser?> get authStateChanges =>
      _remote.authEvents.map(_userFromEvent);

  Future<void> initialize() => _remote.initialize();

  Future<AuthUser?> lightweightAuthentication() async {
    final account = await _remote.lightweightAuthentication();
    return account == null ? null : _toDomain(account);
  }

  Future<AuthUser?> signIn() async {
    try {
      final account = await _remote.signIn();
      return account == null ? null : _toDomain(account);
    } on Failure {
      rethrow;
    } catch (e) {
      throw Failure(message: 'Gagal masuk: $e');
    }
  }

  Future<void> signOut() => _remote.signOut();

  Future<String?> currentIdToken() => _remote.currentIdToken();

  AuthUser? _userFromEvent(GoogleSignInAuthenticationEvent event) =>
      switch (event) {
        GoogleSignInAuthenticationEventSignIn(:final user) => _toDomain(user),
        GoogleSignInAuthenticationEventSignOut() => null,
      };

  AuthUser _toDomain(GoogleSignInAccount account) => AuthUser(
    id: account.id,
    email: account.email,
    displayName: account.displayName,
    photoUrl: account.photoUrl,
    idToken: account.authentication.idToken,
  );
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authRemoteDataSourceProvider)),
);
