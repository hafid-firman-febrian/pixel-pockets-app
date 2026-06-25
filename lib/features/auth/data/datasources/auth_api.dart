import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/auth/data/dtos/auth_session_dto.dart';

/// Calls the public auth endpoints. Uses a DEDICATED Dio without the auth
/// interceptor, so a refresh call never recurses through the interceptor.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<AuthSessionDto> exchangeGoogle(String idToken) async {
    final r = await _dio.post(ApiEndpoints.authGoogle, data: {'idToken': idToken});
    return AuthSessionDto.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  Future<AuthSessionDto> refresh(String refreshToken) async {
    final r = await _dio.post(ApiEndpoints.authRefresh, data: {'refreshToken': refreshToken});
    return AuthSessionDto.fromJson(r.data['data'] as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiEndpoints.authLogout, data: {'refreshToken': refreshToken});
  }

  Future<Map<String, dynamic>> me(String accessToken) async {
    final r = await _dio.get(
      ApiEndpoints.authMe,
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
    return r.data['data'] as Map<String, dynamic>;
  }
}

final authApiProvider = Provider<AuthApi>(
  (ref) => AuthApi(Dio(BaseOptions(
    baseUrl: ApiEndpoints.prodBaseUrl,
    contentType: Headers.jsonContentType,
    // Without these, a hanging endpoint leaves login spinning forever; a
    // timeout surfaces a Failure the UI can show instead. Mirrors ApiClient.
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
  ))),
);
