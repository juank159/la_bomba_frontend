/// Model for resetting password
class ResetPasswordModel {
  final String email;
  final String code;
  final String newPassword;

  const ResetPasswordModel({
    required this.email,
    required this.code,
    required this.newPassword,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    };
  }
}
