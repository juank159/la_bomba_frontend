// lib/app/core/utils/price_input_formatter.dart

import 'package:flutter/services.dart';

/// Input formatter for price fields that automatically formats numbers with thousand separators
/// and removes decimal places.
///
/// Example:
/// - User types "10000" -> displays "10.000"
/// - User types "1500" -> displays "1.500"
class PriceInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // If the new value is empty, return it as is
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digit characters
    String digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // If no digits, return empty
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Format with thousand separators
    String formatted = _formatWithThousandSeparator(digitsOnly);

    // Calculate the new cursor position
    int cursorPosition = formatted.length;

    // If the user was typing (not deleting), put cursor at the end
    if (newValue.text.length > oldValue.text.length) {
      cursorPosition = formatted.length;
    } else {
      // If deleting, try to maintain relative position
      int oldCursorPos = oldValue.selection.baseOffset;
      int diff = oldValue.text.length - newValue.text.length;
      cursorPosition = oldCursorPos - diff;

      // Adjust for separators
      int separatorsBeforeCursor = _countSeparators(
        formatted.substring(0, cursorPosition.clamp(0, formatted.length)),
      );
      cursorPosition = (cursorPosition + separatorsBeforeCursor).clamp(
        0,
        formatted.length,
      );
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }

  /// Format a string of digits with thousand separators (dots)
  String _formatWithThousandSeparator(String digitsOnly) {
    // Reverse the string to make it easier to add separators every 3 digits
    String reversed = digitsOnly.split('').reversed.join('');

    // Add separator every 3 digits
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reversed[i]);
    }

    // Reverse back to get the original order
    return buffer.toString().split('').reversed.join('');
  }

  /// Count the number of thousand separators in a string
  int _countSeparators(String text) {
    return '.'.allMatches(text).length;
  }
}

/// Helper class to parse and format prices
class PriceFormatter {
  /// Parse a formatted price string to a double
  /// Example: "10.000" -> 10000.0
  static double parse(String formattedPrice) {
    if (formattedPrice.isEmpty) return 0.0;

    // Remove thousand separators
    String cleaned = formattedPrice.replaceAll('.', '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Format a double price to a string without decimals
  /// Example: 10000.0 -> "10000"
  static String formatForEditing(double price) {
    return price.toInt().toString();
  }

  /// Format a double price to a display string with thousand separators
  /// Example: 10000.0 -> "10.000"
  static String formatForDisplay(double price) {
    String digitsOnly = price.toInt().toString();

    // Reverse the string
    String reversed = digitsOnly.split('').reversed.join('');

    // Add separator every 3 digits
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(reversed[i]);
    }

    // Reverse back
    return buffer.toString().split('').reversed.join('');
  }

  /// Format a double price to currency display with $ symbol
  /// Example: 10000.0 -> "$10.000"
  static String formatToCurrency(double price) {
    return '\$${formatForDisplay(price)}';
  }
}
