import '../../../../app/core/network/dio_client.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../../../../app/config/api_config.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/request_password_reset_model.dart';
import '../models/verify_reset_code_model.dart';
import '../models/reset_password_model.dart';

/// Abstract class for auth remote data source
abstract class AuthRemoteDataSource {
  /// Login user with email and password
  Future<LoginResponseModel> login(LoginRequestModel request);

  /// Logout user
  Future<void> logout();

  /// Refresh authentication token
  Future<LoginResponseModel> refreshToken(String refreshToken);

  /// Request password reset code
  Future<Map<String, dynamic>?> requestPasswordReset(RequestPasswordResetModel request);

  /// Verify password reset code
  Future<bool> verifyResetCode(VerifyResetCodeModel request);

  /// Reset password with code
  Future<void> resetPassword(ResetPasswordModel request);

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String token);
}

/// Implementation of auth remote data source
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSourceImpl(this._dioClient);

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await _dioClient.post(
        ApiConfig.loginEndpoint,
        data: request.toJson(),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Login failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Login request failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await _dioClient.post(ApiConfig.logoutEndpoint);

      if (response.statusCode != 200) {
        throw ServerException(
          'Logout failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      // If logout fails on server, we can still continue with local logout
      // This is not critical since we'll clear local tokens anyway
      throw ServerException(
        'Logout request failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<LoginResponseModel> refreshToken(String refreshToken) async {
    try {
      final response = await _dioClient.post(
        ApiConfig.refreshTokenEndpoint,
        data: {'refresh_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        return LoginResponseModel.fromJson(response.data);
      } else {
        throw ServerException(
          'Token refresh failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw TokenExpiredException(
        'Token refresh failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> requestPasswordReset(RequestPasswordResetModel request) async {
    try {
      final response = await _dioClient.post(
        '/auth/password/request-reset',
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Request password reset failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }

      // Return response data (may contain code in development mode)
      return response.data as Map<String, dynamic>?;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Request password reset failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> verifyResetCode(VerifyResetCodeModel request) async {
    try {
      final response = await _dioClient.post(
        '/auth/password/verify-code',
        data: request.toJson(),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        return data['valid'] == true;
      } else {
        throw ServerException(
          'Verify reset code failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Verify reset code failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> resetPassword(ResetPasswordModel request) async {
    try {
      final response = await _dioClient.post(
        '/auth/password/reset',
        data: request.toJson(),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Reset password failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Reset password failed: ${e.toString()}',
        originalError: e,
      );
    }
  }

  @override
  Future<void> updateFcmToken(String token) async {
    try {
      final response = await _dioClient.put(
        '/users/fcm-token',
        data: {'fcmToken': token},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Update FCM token failed with status code: ${response.statusCode}',
          code: response.statusCode.toString(),
        );
      }
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException(
        'Update FCM token failed: ${e.toString()}',
        originalError: e,
      );
    }
  }
}