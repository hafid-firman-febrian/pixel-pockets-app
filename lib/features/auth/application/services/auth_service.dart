import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_repository.dart';
import 'package:pixel_pocket/features/auth/domain/models/auth_user.dart';

/// Business logic for authentication. Thin orchestration over the repository;
/// keeps the controller free of data-layer details. Works in [AuthUser] —
/// no SDK types cross this layer.
class AuthService {
  AuthService(this._repo);

  final AuthRepository _repo;

  /// Sign-in / sign-out events (`null` == signed out).
  Stream<AuthUser?> get authStateChanges => _repo.authStateChanges;

  Future<void> initialize() => _repo.initialize();

  Future<AuthUser?> lightweightAuthentication() =>
      _repo.lightweightAuthentication();

  Future<AuthUser?> signIn() => _repo.signIn();

  Future<void> signOut() => _repo.signOut();
}

final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(authRepositoryProvider)),
);
