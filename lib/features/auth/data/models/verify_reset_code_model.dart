/// Model for verifying reset code
class VerifyResetCodeModel {
  final String email;
  final String code;

  const VerifyResetCodeModel({
    required this.email,
    required this.code,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
    };
  }
}
