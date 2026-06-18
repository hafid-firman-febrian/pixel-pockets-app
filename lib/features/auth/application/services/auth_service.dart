import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_repository.dart';

/// Business logic for authentication. Thin orchestration over the repository;
/// keeps the controller free of data-layer details.
class AuthService {
  AuthService(this._repo);

  final AuthRepository _repo;

  Stream<GoogleSignInAuthenticationEvent> get authEvents => _repo.authEvents;

  Future<void> initialize() => _repo.initialize();

  Future<GoogleSignInAccount?> lightweightAuthentication() =>
      _repo.lightweightAuthentication();

  Future<GoogleSignInAccount?> signIn() => _repo.signIn();

  Future<void> signOut() => _repo.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authRepositoryProvider)),
);
