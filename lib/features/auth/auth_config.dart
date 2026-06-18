/// OAuth client identifiers for Google Sign-In.
///
/// Console sebelum menjalankan app. Sebelum diisi, login akan gagal saat
/// runtime (build tetap jalan).
class AuthConfig {
  AuthConfig._();

  /// Web OAuth Client ID. Menjadi klaim `aud` pada ID token, jadi HARUS
  /// sama dengan client ID yang diverifikasi backend.
  static const String serverClientId =
      '442156055928-05t074hk8s0s13asqpfr6upc3pe95fk6.apps.googleusercontent.com';

  /// iOS OAuth Client ID. Boleh dikosongkan kalau sudah diset lewat
  /// `GIDClientID` di ios/Runner/Info.plist (disarankan via Info.plist).
  static const String? iosClientId = null;
}
