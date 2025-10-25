import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Model for login response data
class LoginResponseModel extends Equatable {
  final UserModel user;
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const LoginResponseModel({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 3600,
  });

  /// Create from JSON response
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    try {
      return LoginResponseModel(
        user: UserModel.fromJson(json['user'] ?? json['data'] ?? {}),
        accessToken: json['access_token'] ?? json['accessToken'] ?? json['token'] ?? '',
        refreshToken: json['refresh_token'] ?? json['refreshToken'] ?? '',
        tokenType: json['token_type'] ?? json['tokenType'] ?? 'Bearer',
        expiresIn: json['expires_in'] ?? json['expiresIn'] ?? 3600,
      );
    } catch (e) {
      throw FormatException('Failed to parse LoginResponseModel from JSON: $e');
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
    };
  }

  /// Copy with method for creating modified instances
  LoginResponseModel copyWith({
    UserModel? user,
    String? accessToken,
    String? refreshToken,
    String? tokenType,
    int? expiresIn,
  }) {
    return LoginResponseModel(
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      tokenType: tokenType ?? this.tokenType,
      expiresIn: expiresIn ?? this.expiresIn,
    );
  }

  @override
  List<Object?> get props => [user, accessToken, refreshToken, tokenType, expiresIn];

  @override
  String toString() {
    return 'LoginResponseModel(user: $user, tokenType: $tokenType, expiresIn: $expiresIn)';
  }

  /// Check if tokens are present and valid
  bool get hasValidTokens {
    return accessToken.isNotEmpty && refreshToken.isNotEmpty;
  }

  /// Get expiration timestamp
  DateTime get expirationTime {
    return DateTime.now().add(Duration(seconds: expiresIn));
  }

  /// Check if token is expired (with buffer time)
  bool get isExpired {
    final now = DateTime.now();
    final expiration = expirationTime.subtract(const Duration(minutes: 5)); // 5 min buffer
    return now.isAfter(expiration);
  }
}