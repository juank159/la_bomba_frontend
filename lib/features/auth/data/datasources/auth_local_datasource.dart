import '../../../../app/core/storage/secure_storage.dart';
import '../../../../app/core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../models/login_response_model.dart';

/// Abstract class for auth local data source
abstract class AuthLocalDataSource {
  /// Get access token from secure storage
  Future<String?> getAccessToken();

  /// Get refresh token from secure storage
  Future<String?> getRefreshToken();

  /// Save login response tokens and user data
  Future<void> saveLoginResponse(LoginResponseModel response);

  /// Get current user from local storage
  Future<UserModel?> getCurrentUser();

  /// Save user data to local storage
  Future<void> saveUser(UserModel user);

  /// Check if user is authenticated (has tokens)
  Future<bool> isAuthenticated();

  /// Clear all authentication data
  Future<void> clearAuthData();

  /// Save tokens to secure storage
  Future<void> saveTokens(String accessToken, String refreshToken);
}

/// Implementation of auth local data source using secure storage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;

  AuthLocalDataSourceImpl(this._secureStorage);

  @override
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.getAccessToken();
    } catch (e) {
      throw CacheException(
        'Failed to get access token from storage',
        originalError: e,
      );
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.getRefreshToken();
    } catch (e) {
      throw CacheException(
        'Failed to get refresh token from storage',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveLoginResponse(LoginResponseModel response) async {
    try {
      await _secureStorage.saveLoginSession(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userData: response.user.toJson(),
      );
    } catch (e) {
      throw CacheException(
        'Failed to save login response to storage',
        originalError: e,
      );
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final userData = await _secureStorage.getUserData();
      if (userData == null) return null;

      return UserModel.fromJson(userData);
    } catch (e) {
      throw CacheException(
        'Failed to get current user from storage',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await _secureStorage.saveUserData(user.toJson());
    } catch (e) {
      throw CacheException(
        'Failed to save user to storage',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _secureStorage.isAuthenticated();
    } catch (e) {
      throw CacheException(
        'Failed to check authentication status',
        originalError: e,
      );
    }
  }

  @override
  Future<void> clearAuthData() async {
    try {
      await _secureStorage.clearAuthData();
    } catch (e) {
      throw CacheException(
        'Failed to clear authentication data',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    try {
      await _secureStorage.saveTokens(accessToken, refreshToken);
    } catch (e) {
      throw CacheException(
        'Failed to save tokens to storage',
        originalError: e,
      );
    }
  }
}