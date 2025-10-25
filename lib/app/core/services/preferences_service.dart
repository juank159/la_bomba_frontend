// lib/app/core/services/preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app preferences
class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';
  static const String _savedEmailsKey = 'saved_emails';
  static const String _lastEmailKey = 'last_email';
  static const int _maxSavedEmails = 5; // Maximum number of emails to save

  late final SharedPreferences _prefs;

  /// Initialize the preferences service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get the saved theme mode
  /// Returns: 'light', 'dark', or 'system'
  String getThemeMode() {
    return _prefs.getString(_themeKey) ?? 'system';
  }

  /// Save the theme mode
  /// Accepts: 'light', 'dark', or 'system'
  Future<bool> setThemeMode(String mode) async {
    return await _prefs.setString(_themeKey, mode);
  }

  /// Get the saved theme color
  /// Returns: 'blue', 'green', 'purple', 'red', 'orange', or 'pink'
  String getThemeColor() {
    return _prefs.getString(_themeColorKey) ?? 'blue';
  }

  /// Save the theme color
  /// Accepts: 'blue', 'green', 'purple', 'red', 'orange', or 'pink'
  Future<bool> setThemeColor(String color) async {
    return await _prefs.setString(_themeColorKey, color);
  }

  /// Get list of saved emails
  List<String> getSavedEmails() {
    final emails = _prefs.getStringList(_savedEmailsKey) ?? [];
    return emails;
  }

  /// Save an email to the list (adds to front, removes duplicates, limits to max)
  Future<bool> saveEmail(String email) async {
    if (email.trim().isEmpty) return false;

    final emails = getSavedEmails();

    // Remove if already exists (will re-add to front)
    emails.remove(email);

    // Add to front
    emails.insert(0, email);

    // Keep only the most recent emails up to the limit
    if (emails.length > _maxSavedEmails) {
      emails.removeRange(_maxSavedEmails, emails.length);
    }

    return await _prefs.setStringList(_savedEmailsKey, emails);
  }

  /// Get the last used email
  String? getLastEmail() {
    return _prefs.getString(_lastEmailKey);
  }

  /// Save the last used email
  Future<bool> setLastEmail(String email) async {
    return await _prefs.setString(_lastEmailKey, email);
  }

  /// Remove an email from saved emails
  Future<bool> removeEmail(String email) async {
    final emails = getSavedEmails();
    emails.remove(email);
    return await _prefs.setStringList(_savedEmailsKey, emails);
  }

  /// Clear all saved emails
  Future<bool> clearSavedEmails() async {
    await _prefs.remove(_savedEmailsKey);
    return await _prefs.remove(_lastEmailKey);
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
