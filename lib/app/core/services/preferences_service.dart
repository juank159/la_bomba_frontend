// lib/app/core/services/preferences_service.dart

import 'package:shared_preferences/shared_preferences.dart';

import 'printer_destination.dart';

/// Service for managing app preferences
class PreferencesService {
  static const String _themeKey = 'theme_mode';
  static const String _themeColorKey = 'theme_color';
  static const String _savedEmailsKey = 'saved_emails';
  static const String _lastEmailKey = 'last_email';
  static const int _maxSavedEmails = 5; // Maximum number of emails to save
  static const String _printerIpKey = 'thermal_printer_ip';
  static const String _printerPortKey = 'thermal_printer_port';
  static const String _printerConnectionTypeKey = 'thermal_printer_connection_type';
  static const String _printerUsbNameKey = 'thermal_printer_usb_name';
  static const String _scalePortKey = 'vegetable_scale_serial_port';
  static const String _scaleBaudRateKey = 'vegetable_scale_baud_rate';

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

  /// Get the saved thermal printer IP address (network ESC/POS printer)
  String? getPrinterIp() {
    return _prefs.getString(_printerIpKey);
  }

  /// Save the thermal printer IP address
  Future<bool> setPrinterIp(String ip) async {
    return await _prefs.setString(_printerIpKey, ip);
  }

  /// Get the saved thermal printer port (defaults to the standard ESC/POS port 9100)
  int getPrinterPort() {
    return _prefs.getInt(_printerPortKey) ?? 9100;
  }

  /// Save the thermal printer port
  Future<bool> setPrinterPort(int port) async {
    return await _prefs.setInt(_printerPortKey, port);
  }

  /// Get how the thermal printer is reached: over the network (default,
  /// for backwards compatibility with installs that only ever set an IP)
  /// or via a USB printer installed in Windows.
  PrinterConnectionType getPrinterConnectionType() {
    final raw = _prefs.getString(_printerConnectionTypeKey);
    return raw == 'usb' ? PrinterConnectionType.usb : PrinterConnectionType.network;
  }

  /// Save how the thermal printer is reached (network or usb)
  Future<bool> setPrinterConnectionType(PrinterConnectionType type) async {
    return await _prefs.setString(
      _printerConnectionTypeKey,
      type == PrinterConnectionType.usb ? 'usb' : 'network',
    );
  }

  /// Get the exact Windows printer name selected for USB printing
  String? getPrinterUsbName() {
    return _prefs.getString(_printerUsbNameKey);
  }

  /// Save the Windows printer name selected for USB printing
  Future<bool> setPrinterUsbName(String name) async {
    return await _prefs.setString(_printerUsbNameKey, name);
  }

  /// Builds the printer destination every feature that prints a receipt
  /// (Facturación, Verduras, ...) should use, from the single shared
  /// "Impresora Térmica" configuration. Returns null when nothing usable
  /// is configured yet for the selected connection type.
  PrinterDestination? getPrinterDestination() {
    if (getPrinterConnectionType() == PrinterConnectionType.usb) {
      final name = getPrinterUsbName();
      if (name == null || name.isEmpty) return null;
      return PrinterDestination.usb(usbPrinterName: name);
    }

    final ip = getPrinterIp();
    if (ip == null || ip.isEmpty) return null;
    return PrinterDestination.network(ip: ip, port: getPrinterPort());
  }

  /// Get the saved serial port name/path for the vegetable scale
  /// (e.g. "COM3" on Windows, "/dev/tty.usbserial-XXXX" on macOS/Linux)
  String? getScalePort() {
    return _prefs.getString(_scalePortKey);
  }

  /// Save the serial port used to connect to the vegetable scale
  Future<bool> setScalePort(String port) async {
    return await _prefs.setString(_scalePortKey, port);
  }

  /// Get the saved baud rate for the vegetable scale (default 9600, the
  /// most common rate for this kind of bench scale)
  int getScaleBaudRate() {
    return _prefs.getInt(_scaleBaudRateKey) ?? 9600;
  }

  /// Save the baud rate used to connect to the vegetable scale
  Future<bool> setScaleBaudRate(int baudRate) async {
    return await _prefs.setInt(_scaleBaudRateKey, baudRate);
  }

  /// Clear all preferences
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
