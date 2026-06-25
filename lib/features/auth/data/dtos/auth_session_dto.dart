/// Wire representation of `/api/auth/google` and `/api/auth/refresh` `data`.
/// `/refresh` omits `user`, so identity fields default to empty strings.
class AuthSessionDto {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String email;
  final String sub;
  final String name;

  const AuthSessionDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.email,
    required this.sub,
    required this.name,
  });

  factory AuthSessionDto.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return AuthSessionDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      email: (user?['email'] as String?) ?? '',
      sub: (user?['sub'] as String?) ?? '',
      name: (user?['name'] as String?) ?? '',
    );
  }
}
