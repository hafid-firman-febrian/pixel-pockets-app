import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:pixel_pocket/features/auth/data/datasources/auth_remote_data_source.dart';

const driveFileScope = 'https://www.googleapis.com/auth/drive.file';

class SheetsAuthException implements Exception {
  const SheetsAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class GoogleAuthClient {
  GoogleAuthClient(this._auth);

  final AuthRemoteDataSource _auth;

  Future<String> connect() async {
    await _auth.initialize();
    final account = await _auth.signIn();
    if (account == null) {
      throw const SheetsAuthException('Sign-in cancelled.');
    }
    await GoogleSignIn.instance.authorizationClient.authorizeScopes([
      driveFileScope,
    ]);
    return account.email;
  }

  http.Client authedClient() => _AuthedClient();

  Future<void> disconnect() async {
    await _auth.signOut();
  }
}

class _AuthedClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final headers = await GoogleSignIn.instance.authorizationClient
        .authorizationHeaders([driveFileScope], promptIfNecessary: false);
    if (headers == null) {
      throw const SheetsAuthException(
        'Google authorization expired. Reconnect required.',
      );
    }
    request.headers.addAll(headers);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final googleAuthClientProvider = Provider<GoogleAuthClient>(
  (ref) => GoogleAuthClient(ref.watch(authRemoteDataSourceProvider)),
);
