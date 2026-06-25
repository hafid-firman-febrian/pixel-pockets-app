import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/data/dtos/auth_session_dto.dart';

void main() {
  test('parses /auth/google data with user', () {
    final dto = AuthSessionDto.fromJson({
      'accessToken': 'jwt-abc',
      'refreshToken': 'opaque-xyz',
      'expiresIn': 1800,
      'user': {'email': 'a@b.com', 'sub': 'sub-1', 'name': 'Hafid'},
    });
    expect(dto.accessToken, 'jwt-abc');
    expect(dto.refreshToken, 'opaque-xyz');
    expect(dto.expiresIn, 1800);
    expect(dto.email, 'a@b.com');
    expect(dto.sub, 'sub-1');
    expect(dto.name, 'Hafid');
  });

  test('parses /auth/refresh data without user (name empty)', () {
    final dto = AuthSessionDto.fromJson({
      'accessToken': 'jwt-2',
      'refreshToken': 'opaque-2',
      'expiresIn': 1800,
    });
    expect(dto.accessToken, 'jwt-2');
    expect(dto.refreshToken, 'opaque-2');
    expect(dto.name, '');
    expect(dto.email, '');
  });
}
