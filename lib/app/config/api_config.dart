// lib/app/config/api_config.dart
/// API Configuration settings for the Pedidos application
class ApiConfig {
  // Environment configuration
  static const bool isDevelopment = false; // false = usa producción en Render

  // Base URLs for different environments
  static const String developmentUrl = 'http://192.168.1.249:3000';
  static const String productionUrl =
      'https://la-bomba.onrender.com'; // ✅ API en Render

  // Dynamic base URL based on environment
  static String get baseUrl => isDevelopment ? developmentUrl : productionUrl;

  // Timeout configurations (increased for Render free tier cold starts)
  static const int connectTimeout =
      60000; // 60 seconds (Render puede tardar al despertar)
  static const int receiveTimeout =
      90000; // 90 seconds (email sending puede tardar mucho)
  static const int sendTimeout = 45000; // 45 seconds

  // API Endpoints
  static const String authEndpoints = '/auth';
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';

  static const String productsEndpoint = '/products';
  static const String ordersEndpoint = '/orders';
  static const String creditsEndpoint = '/credits';
  static const String expensesEndpoint = '/expenses';
  static const String todosEndpoint = '/todos';
  static const String usersEndpoint = '/users';
  static const String clientsEndpoint = '/clients';
  static const String suppliersEndpoint = '/suppliers';

  // Header keys
  static const String authorizationHeader = 'Authorization';
  static const String contentTypeHeader = 'Content-Type';
  static const String acceptHeader = 'Accept';

  // Content types
  static const String jsonContentType = 'application/json';

  // Token prefix
  static const String bearerPrefix = 'Bearer ';

  // Storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';

  // API versioning
  static const String apiVersion = 'v1';

  /// Get full URL for an endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Get versioned endpoint
  static String getVersionedEndpoint(String endpoint) {
    return '/api/$apiVersion$endpoint';
  }
}
