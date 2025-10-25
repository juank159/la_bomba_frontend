// lib/app/core/controllers/theme_controller.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/preferences_service.dart';
import '../../config/app_config.dart';

/// Controller for managing app theme
class ThemeController extends GetxController {
  final PreferencesService _preferencesService;

  ThemeController({required PreferencesService preferencesService})
      : _preferencesService = preferencesService;

  // Observable theme mode
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;

  // Observable theme color
  final Rx<String> _themeColor = 'blue'.obs;

  ThemeMode get themeMode => _themeMode.value;
  String get themeColor => _themeColor.value;
  Color get currentColor => AppConfig.getColorByName(_themeColor.value);

  // Get current theme data based on mode and color
  ThemeData get lightTheme => AppConfig.getThemeData(currentColor, Brightness.light);
  ThemeData get darkTheme => AppConfig.getThemeData(currentColor, Brightness.dark);

  @override
  void onInit() {
    super.onInit();
    _loadThemePreferences();
  }

  /// Load saved theme preferences from storage
  void _loadThemePreferences() {
    // Load theme mode
    final savedMode = _preferencesService.getThemeMode();
    switch (savedMode) {
      case 'light':
        _themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        _themeMode.value = ThemeMode.system;
        break;
    }

    // Load theme color
    final savedColor = _preferencesService.getThemeColor();
    _themeColor.value = savedColor;

    // Apply the theme immediately
    _applyTheme();
  }

  /// Apply current theme
  void _applyTheme() {
    // Simply update the theme mode - the Obx wrapper in main.dart
    // will automatically rebuild with new themes when observables change
    Get.changeThemeMode(_themeMode.value);
  }

  /// Change theme to light mode
  Future<void> setLightTheme() async {
    _themeMode.value = ThemeMode.light;
    await _preferencesService.setThemeMode('light');
    _applyTheme();
  }

  /// Change theme to dark mode
  Future<void> setDarkTheme() async {
    _themeMode.value = ThemeMode.dark;
    await _preferencesService.setThemeMode('dark');
    _applyTheme();
  }

  /// Change theme to system mode (follows device settings)
  Future<void> setSystemTheme() async {
    _themeMode.value = ThemeMode.system;
    await _preferencesService.setThemeMode('system');
    _applyTheme();
  }

  /// Change theme color
  Future<void> setThemeColor(String colorName) async {
    _themeColor.value = colorName;
    await _preferencesService.setThemeColor(colorName);
    _applyTheme();
  }

  /// Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode.value == ThemeMode.light) {
      await setDarkTheme();
    } else {
      await setLightTheme();
    }
  }

  /// Check if current theme is dark
  bool get isDarkMode {
    if (_themeMode.value == ThemeMode.system) {
      // Check device brightness
      return Get.isDarkMode;
    }
    return _themeMode.value == ThemeMode.dark;
  }

  /// Check if current theme is light
  bool get isLightMode {
    if (_themeMode.value == ThemeMode.system) {
      // Check device brightness
      return !Get.isDarkMode;
    }
    return _themeMode.value == ThemeMode.light;
  }

  /// Check if current theme is system
  bool get isSystemMode => _themeMode.value == ThemeMode.system;

  /// Get theme mode as string for display
  String get themeModeString {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return 'Claro';
      case ThemeMode.dark:
        return 'Oscuro';
      case ThemeMode.system:
        return 'Sistema';
    }
  }

  /// Get theme color as string for display
  String get themeColorString {
    switch (_themeColor.value) {
      case 'blue':
        return 'Azul';
      case 'green':
        return 'Verde';
      case 'purple':
        return 'Morado';
      case 'red':
        return 'Rojo';
      case 'orange':
        return 'Naranja';
      case 'pink':
        return 'Rosa';
      default:
        return 'Azul';
    }
  }

  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode.value) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}
