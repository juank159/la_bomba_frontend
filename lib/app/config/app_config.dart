import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Application configuration and constants
class AppConfig {
  // App basic information
  static const String appName = 'La Bomba';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Sistema de gestión de Negocio';
  static const String companyName = 'La Bomba  Company';

  // Environment settings
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;

  // Theme configuration
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03DAC6);
  static const Color errorColor = Color(0xFFB00020);
  static const Color warningColor = Color(0xFFF57C00);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color surfaceColor = Color(0xFFFFFFFF);

  // Dark theme colors
  static const Color darkPrimaryColor = Color(0xFF1976D2);
  static const Color darkSecondaryColor = Color(0xFF018786);
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color darkSurfaceColor = Color(0xFF1E1E1E);

  // Theme color options
  static const Color blueColor = Color(0xFF2196F3); // Azul
  static const Color greenColor = Color(0xFF4CAF50); // Verde
  static const Color purpleColor = Color(0xFF9C27B0); // Morado
  static const Color redColor = Color(0xFFE53935); // Rojo
  static const Color orangeColor = Color(0xFFFF9800); // Naranja
  static const Color pinkColor = Color(0xFFEC407A); // Rosa suave

  // Text theme
  static const String fontFamily = 'Roboto';
  static const double titleFontSize = 24.0;
  static const double headingFontSize = 20.0;
  static const double bodyFontSize = 16.0;
  static const double captionFontSize = 14.0;
  static const double smallFontSize = 12.0;

  // Spacing and dimensions
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double marginSmall = 8.0;
  static const double marginMedium = 16.0;
  static const double marginLarge = 24.0;

  static const double borderRadius = 8.0;
  static const double borderRadiusLarge = 16.0;
  static const double buttonHeight = 48.0;
  static const double inputHeight = 56.0;

  // Animation durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationMedium = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);

  // Validation constants
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Cache settings
  static const Duration cacheValidDuration = Duration(minutes: 5);
  static const Duration tokenRefreshBuffer = Duration(minutes: 2);

  // UI Messages
  static const String genericErrorMessage =
      'Ha ocurrido un error. Por favor intenta nuevamente.';
  static const String networkErrorMessage =
      'Error de conexión. Verifica tu internet.';
  static const String unauthorizedMessage =
      'Sesión expirada. Por favor inicia sesión nuevamente.';
  static const String notFoundMessage = 'Recurso no encontrado.';
  static const String serverErrorMessage =
      'Error del servidor. Por favor intenta más tarde.';

  // Date and time formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';
  static const String apiDateTimeFormat = 'yyyy-MM-ddTHH:mm:ss.SSSZ';

  // Feature flags
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableBiometricAuth = true;
  static const bool enableDarkMode = true;

  // Image settings
  static const double maxImageSizeMB = 5.0;
  static const int imageQuality = 80;

  /// Get theme data for light theme
  static ThemeData get lightTheme => getThemeData(blueColor, Brightness.light);

  /// Get theme data for dark theme
  static ThemeData get darkTheme => getThemeData(blueColor, Brightness.dark);

  /// Get theme data with custom color
  static ThemeData getThemeData(Color seedColor, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: brightness,
      ),
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        filled: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingMedium,
          vertical: paddingMedium,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }

  /// Get color by name
  static Color getColorByName(String colorName) {
    switch (colorName) {
      case 'blue':
        return blueColor;
      case 'green':
        return greenColor;
      case 'purple':
        return purpleColor;
      case 'red':
        return redColor;
      case 'orange':
        return orangeColor;
      case 'pink':
        return pinkColor;
      default:
        return blueColor;
    }
  }

  /// Get color name from Color
  static String getColorName(Color color) {
    if (color == blueColor) return 'blue';
    if (color == greenColor) return 'green';
    if (color == purpleColor) return 'purple';
    if (color == redColor) return 'red';
    if (color == orangeColor) return 'orange';
    if (color == pinkColor) return 'pink';
    return 'blue';
  }
}
