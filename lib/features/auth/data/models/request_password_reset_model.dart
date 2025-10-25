/// Model for requesting password reset
class RequestPasswordResetModel {
  final String email;

  const RequestPasswordResetModel({
    required this.email,
  });

  /// Convert to JSON for API request
  Map<String, dynamic> toJson() {
    return {
      'email': email,
    };
  }
}
