import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../errors/exceptions.dart';
import '../../config/api_config.dart';

/// Abstract interface for secure storage
abstract class SecureStorage {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
  Future<Map<String, String>> readAll();
  Future<void> writeJson(String key, Map<String, dynamic> json);
  Future<Map<String, dynamic>?> readJson(String key);
  
  // Authentication methods
  Future<void> saveAccessToken(String token);
  Future<String?> getAccessToken();
  Future<void> deleteAccessToken();
  Future<bool> isAuthenticated();
  
  // Extended authentication methods
  Future<String?> getRefreshToken();
  Future<void> saveRefreshToken(String token);
  Future<void> deleteRefreshToken();
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<void> deleteTokens();
  Future<void> clearAuthData();
  
  // User data methods
  Future<void> saveUserData(Map<String, dynamic> userData);
  Future<Map<String, dynamic>?> getUserData();
  Future<void> deleteUserData();
  
  // Session management
  Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  });
}

/// Implementation of secure storage using FlutterSecureStorage
class SecureStorageImpl implements SecureStorage {
  final FlutterSecureStorage _storage;
  
  // Fallback in-memory storage for development
  static final Map<String, String> _memoryStorage = {};
  
  SecureStorageImpl(this._storage);

  @override
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      print('✅ Token saved to secure storage');
    } catch (e) {
      print('⚠️ SecureStorage write failed: $e');
      // Fallback: use in-memory storage
      _memoryStorage[key] = value;
      print('✅ Token saved to memory fallback');
    }
  }

  @override
  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value != null) return value;
    } catch (e) {
      print('⚠️ SecureStorage read failed: $e');
    }
    
    // Fallback: try memory storage
    return _memoryStorage[key];
  }

  @override
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      print('⚠️ SecureStorage delete failed: $e');
    }
    
    // Also remove from memory fallback
    _memoryStorage.remove(key);
  }

  @override
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
        'Failed to clear secure storage',
        code: 'STORAGE_CLEAR_ERROR',
        originalError: e,
      );
    }
  }

  @override
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to check key in secure storage',
        code: 'STORAGE_CHECK_ERROR',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw SecureStorageException(
        'Failed to read all from secure storage',
        code: 'STORAGE_READ_ALL_ERROR',
        originalError: e,
      );
    }
  }

  @override
  Future<void> writeJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      await write(key, jsonString);
    } catch (e) {
      throw SecureStorageException(
        'Failed to write JSON to secure storage',
        code: 'STORAGE_JSON_WRITE_ERROR',
        originalError: e,
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final jsonString = await read(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException(
        'Failed to read JSON from secure storage',
        code: 'STORAGE_JSON_READ_ERROR',
        originalError: e,
      );
    }
  }

  @override
  Future<void> saveAccessToken(String token) async {
    await write(ApiConfig.accessTokenKey, token);
  }

  @override
  Future<String?> getAccessToken() async {
    return await read(ApiConfig.accessTokenKey);
  }

  @override
  Future<void> deleteAccessToken() async {
    await delete(ApiConfig.accessTokenKey);
  }

  @override
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  @override
  Future<String?> getRefreshToken() async {
    return await read(ApiConfig.refreshTokenKey);
  }

  @override
  Future<void> saveRefreshToken(String token) async {
    await write(ApiConfig.refreshTokenKey, token);
  }

  @override
  Future<void> deleteRefreshToken() async {
    await delete(ApiConfig.refreshTokenKey);
  }

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  @override
  Future<void> deleteTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }

  @override
  Future<void> clearAuthData() async {
    await Future.wait([
      deleteTokens(),
      deleteUserData(),
    ]);
  }

  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await writeJson(ApiConfig.userDataKey, userData);
  }

  @override
  Future<Map<String, dynamic>?> getUserData() async {
    return await readJson(ApiConfig.userDataKey);
  }

  @override
  Future<void> deleteUserData() async {
    await delete(ApiConfig.userDataKey);
  }

  @override
  Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserData(userData),
    ]);
  }
}

/// Legacy service class - keeping for backward compatibility
class SecureStorageService extends SecureStorageImpl {
  SecureStorageService() : super(const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'pedidos_secure_prefs',
      preferencesKeyPrefix: 'pedidos_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.pedidos.pedidos_frontend',
      accountName: 'pedidos_account',
      synchronizable: true,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
  ));

  // Additional methods for backward compatibility
  static const FlutterSecureStorage _staticStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      sharedPreferencesName: 'pedidos_secure_prefs',
      preferencesKeyPrefix: 'pedidos_',
    ),
    iOptions: IOSOptions(
      groupId: 'group.com.pedidos.pedidos_frontend',
      accountName: 'pedidos_account',
      synchronizable: true,
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    lOptions: LinuxOptions(),
    wOptions: WindowsOptions(),
  );

  /// Write a string value to secure storage
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException(
        'Failed to write to secure storage',
        code: 'STORAGE_WRITE_ERROR',
        originalError: e,
      );
    }
  }

  /// Read a string value from secure storage
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to read from secure storage',
        code: 'STORAGE_READ_ERROR',
        originalError: e,
      );
    }
  }

  /// Delete a value from secure storage
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to delete from secure storage',
        code: 'STORAGE_DELETE_ERROR',
        originalError: e,
      );
    }
  }

  /// Clear all values from secure storage
  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
        'Failed to clear secure storage',
        code: 'STORAGE_CLEAR_ERROR',
        originalError: e,
      );
    }
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey(String key) async {
    try {
      return await _storage.containsKey(key: key);
    } catch (e) {
      throw SecureStorageException(
        'Failed to check key in secure storage',
        code: 'STORAGE_CHECK_ERROR',
        originalError: e,
      );
    }
  }

  /// Get all keys from secure storage
  Future<Map<String, String>> readAll() async {
    try {
      return await _storage.readAll();
    } catch (e) {
      throw SecureStorageException(
        'Failed to read all from secure storage',
        code: 'STORAGE_READ_ALL_ERROR',
        originalError: e,
      );
    }
  }

  /// Write a JSON object to secure storage
  Future<void> writeJson(String key, Map<String, dynamic> json) async {
    try {
      final jsonString = jsonEncode(json);
      await write(key, jsonString);
    } catch (e) {
      throw SecureStorageException(
        'Failed to write JSON to secure storage',
        code: 'STORAGE_JSON_WRITE_ERROR',
        originalError: e,
      );
    }
  }

  /// Read a JSON object from secure storage
  Future<Map<String, dynamic>?> readJson(String key) async {
    try {
      final jsonString = await read(key);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw SecureStorageException(
        'Failed to read JSON from secure storage',
        code: 'STORAGE_JSON_READ_ERROR',
        originalError: e,
      );
    }
  }

  // Authentication Token Methods

  /// Save access token
  Future<void> saveAccessToken(String token) async {
    await write(ApiConfig.accessTokenKey, token);
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await read(ApiConfig.accessTokenKey);
  }

  /// Delete access token
  Future<void> deleteAccessToken() async {
    await delete(ApiConfig.accessTokenKey);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    await write(ApiConfig.refreshTokenKey, token);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await read(ApiConfig.refreshTokenKey);
  }

  /// Delete refresh token
  Future<void> deleteRefreshToken() async {
    await delete(ApiConfig.refreshTokenKey);
  }

  /// Save both access and refresh tokens
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
    ]);
  }

  /// Delete both access and refresh tokens
  Future<void> deleteTokens() async {
    await Future.wait([
      deleteAccessToken(),
      deleteRefreshToken(),
    ]);
  }

  /// Check if user is authenticated (has access token)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  // User Data Methods

  /// Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await writeJson(ApiConfig.userDataKey, userData);
  }

  /// Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    return await readJson(ApiConfig.userDataKey);
  }

  /// Delete user data
  Future<void> deleteUserData() async {
    await delete(ApiConfig.userDataKey);
  }

  // Session Management

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    await Future.wait([
      deleteTokens(),
      deleteUserData(),
    ]);
  }

  /// Save login session (tokens + user data)
  Future<void> saveLoginSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userData,
  }) async {
    await Future.wait([
      saveAccessToken(accessToken),
      saveRefreshToken(refreshToken),
      saveUserData(userData),
    ]);
  }

  // App Settings Methods

  /// Save app setting
  Future<void> saveSetting(String key, String value) async {
    await write('setting_$key', value);
  }

  /// Get app setting
  Future<String?> getSetting(String key) async {
    return await read('setting_$key');
  }

  /// Delete app setting
  Future<void> deleteSetting(String key) async {
    await delete('setting_$key');
  }

  /// Save app settings as JSON
  Future<void> saveSettingsJson(Map<String, dynamic> settings) async {
    await writeJson('app_settings', settings);
  }

  /// Get app settings as JSON
  Future<Map<String, dynamic>?> getSettingsJson() async {
    return await readJson('app_settings');
  }

  // Biometric Settings

  /// Save biometric enabled preference
  Future<void> setBiometricEnabled(bool enabled) async {
    await write('biometric_enabled', enabled.toString());
  }

  /// Get biometric enabled preference
  Future<bool> isBiometricEnabled() async {
    final value = await read('biometric_enabled');
    return value?.toLowerCase() == 'true';
  }

  // Theme Settings

  /// Save theme mode preference
  Future<void> setThemeMode(String themeMode) async {
    await write('theme_mode', themeMode);
  }

  /// Get theme mode preference
  Future<String?> getThemeMode() async {
    return await read('theme_mode');
  }

  // Language Settings

  /// Save language preference
  Future<void> setLanguage(String languageCode) async {
    await write('language_code', languageCode);
  }

  /// Get language preference
  Future<String?> getLanguage() async {
    return await read('language_code');
  }

  // Developer/Debug Methods

  /// Get all stored keys (for debugging)
  Future<List<String>> getAllKeys() async {
    try {
      final allData = await readAll();
      return allData.keys.toList();
    } catch (e) {
      throw SecureStorageException(
        'Failed to get all keys from secure storage',
        code: 'STORAGE_GET_KEYS_ERROR',
        originalError: e,
      );
    }
  }

  /// Print all stored data (for debugging - only in debug mode)
  Future<void> debugPrintAll() async {
    assert(() {
      readAll().then((data) {
        print('=== Secure Storage Debug ===');
        data.forEach((key, value) {
          // Don't print actual token values for security
          if (key.contains('token')) {
            print('$key: [HIDDEN_TOKEN]');
          } else {
            print('$key: $value');
          }
        });
        print('========================');
      });
      return true;
    }());
  }
}