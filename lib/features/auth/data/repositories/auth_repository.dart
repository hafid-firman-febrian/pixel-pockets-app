import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';

/// Auth data-layer API. Delegates to [AuthRemoteDataSource]; exists so higher
/// layers depend on a repository rather than the SDK wrapper directly.
class AuthRepository {
  AuthRepository(this._remote);

  final AuthRemoteDataSource _remote;

  Stream<GoogleSignInAuthenticationEvent> get authEvents => _remote.authEvents;

  Future<void> initialize() => _remote.initialize();

  Future<GoogleSignInAccount?> lightweightAuthentication() =>
      _remote.lightweightAuthentication();

  Future<GoogleSignInAccount?> signIn() => _remote.signIn();

  Future<void> signOut() => _remote.signOut();

  Future<String?> currentIdToken() => _remote.currentIdToken();
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(authRemoteDataSourceProvider)),
);
