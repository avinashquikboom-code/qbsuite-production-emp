import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/errors/app_failure.dart';
import '../domain/session.dart';

class AuthService {
  AuthService(this._dio);
  final Dio _dio;
  Future<Session> signIn(String email, String password) async {
    try {
      final response = await _dio.post<Object?>(
        AppConfig.loginEndpoint,
        data: {'email': loginIdentifier(email), 'password': password},
        options: Options(extra: {'public': true}),
      );
      final body = response.data;
      if (body is! Map) throw const AppFailure('Invalid sign-in response.');
      final payload = body['data'] is Map ? body['data'] as Map : body;
      final tokens = payload['tokens'];
      final user = payload['user'];
      final token = tokens is Map
          ? tokens['accessToken']
          : payload['accessToken'];
      if (user is! Map || token is! String || token.trim().isEmpty) {
        throw const AppFailure('Invalid sign-in response.');
      }
      final role = user['role']?.toString().toUpperCase();
      if (!AppConfig.allowedRoles.contains(role)) {
        throw const AppFailure('This account cannot access this application.');
      }
      return Session(
        accessToken: token,
        email: user['email']?.toString() ?? email.trim(),
        role: role!,
      );
    } on DioException catch (error) {
      final message = _serverMessage(error);
      if (error.response?.statusCode == 401) {
        throw AppFailure(
          message ?? 'Employee ID, email, mobile, or password is incorrect.',
        );
      }
      if (message != null) throw AppFailure(message);
      throw error.error is AppFailure
          ? error.error!
          : AppFailure.fromDio(error);
    }
  }
}

/// The employee login API accepts an email, employee code, or mobile number
/// in the same `email` field.
String loginIdentifier(String raw) {
  final value = raw.trim();
  if (value.contains('@')) return value.toLowerCase();
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (!RegExp(r'[A-Za-z]').hasMatch(value) && digits.length >= 10) {
    return digits.substring(digits.length - 10);
  }
  return value.replaceAll(RegExp(r'\s+'), '');
}

String? _serverMessage(DioException error) {
  final data = error.response?.data;
  if (data is! Map) return null;
  final message = data['message'];
  final text = message is List ? message.join('\n') : message?.toString();
  if (text == null || text.trim().isEmpty) return null;
  return text.trim();
}
