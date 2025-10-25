import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Application logger utility using the logger package
class AppLogger {
  static late Logger _logger;
  static bool _initialized = false;
  
  /// Initialize the logger with appropriate settings
  static void init() {
    if (_initialized) return;
    
    _logger = Logger(
      filter: ProductionFilter(),
      printer: PrettyPrinter(
        methodCount: kDebugMode ? 2 : 0,
        errorMethodCount: kDebugMode ? 8 : 0,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: ConsoleOutput(),
    );
    
    _initialized = true;
  }
  
  /// Log a debug message
  static void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.d(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log an info message
  static void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.i(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a warning message
  static void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.w(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log an error message
  static void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a verbose message
  static void verbose(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.t(message, error: error, stackTrace: stackTrace);
  }
  
  /// Log a trace message (WTF level - What a Terrible Failure)
  static void wtf(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _ensureInitialized();
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
  
  /// Ensure logger is initialized before use
  static void _ensureInitialized() {
    if (!_initialized) {
      init();
    }
  }
}

/// Production filter that only shows warnings and errors in release mode
class ProductionFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kReleaseMode) {
      // In release mode, only log warnings and errors
      return event.level.index >= Level.warning.index;
    }
    // In debug mode, log everything
    return true;
  }
}