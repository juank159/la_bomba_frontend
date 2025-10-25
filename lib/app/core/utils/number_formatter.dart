// lib/app/core/utils/number_formatter.dart

/// Utilidades para formatear números y precios
class NumberFormatter {
  // Formatter para precios sin decimales (usando formato personalizado sin locale)
  static String _formatNumber(num number) {
    final parts = number.toStringAsFixed(0).split('');
    final reversed = parts.reversed.toList();
    final formatted = <String>[];

    for (var i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted.add('.');
      }
      formatted.add(reversed[i]);
    }

    return formatted.reversed.join('');
  }

  // Formatter para precios con decimales
  static String _formatNumberWithDecimals(num number) {
    final intPart = number.floor();
    final decimalPart = ((number - intPart) * 100).round();
    return '${_formatNumber(intPart)},${decimalPart.toString().padLeft(2, '0')}';
  }

  /// Formatea un número como precio sin decimales
  /// Ejemplo: 8500.0 -> "8.500"
  static String formatPrice(double? price) {
    if (price == null) return '0';
    return _formatNumber(price.round());
  }

  /// Formatea un número como precio con decimales
  /// Ejemplo: 8500.50 -> "8.500,50"
  static String formatPriceWithDecimals(double? price) {
    if (price == null) return '0,00';
    return _formatNumberWithDecimals(price);
  }

  /// Formatea un número como moneda colombiana
  /// Ejemplo: 8500.0 -> "$8.500"
  static String formatCurrency(double? price) {
    if (price == null) return '\$0';
    return '\$${_formatNumber(price.round())}';
  }

  /// Formatea un número como moneda con símbolo personalizado
  /// Ejemplo: 8500.0 -> "$8.500"
  static String formatCurrencyWithSymbol(
    double? price, {
    String symbol = '\$',
  }) {
    if (price == null) return '${symbol}0';
    return '$symbol${_formatNumber(price.round())}';
  }

  /// Formatea un porcentaje
  /// Ejemplo: 19.0 -> "19%"
  static String formatPercentage(double? percentage) {
    if (percentage == null) return '0%';
    return '${percentage.toStringAsFixed(percentage % 1 == 0 ? 0 : 1)}%';
  }

  /// Convierte un string de precio a double
  /// Ejemplo: "8.500" -> 8500.0
  static double? parsePrice(String? priceString) {
    if (priceString == null || priceString.isEmpty) return null;

    // Remover puntos de miles y convertir comas decimales a puntos
    final cleanedString = priceString
        .replaceAll('.', '') // Remover separadores de miles
        .replaceAll(',', '.'); // Convertir separador decimal

    return double.tryParse(cleanedString);
  }

  /// Formatea un número entero con separadores de miles
  /// Ejemplo: 1234567 -> "1.234.567"
  static String formatInteger(int? number) {
    if (number == null) return '0';
    return _formatNumber(number);
  }

  /// Verifica si un precio es válido (mayor a 0)
  static bool isValidPrice(double? price) {
    return price != null && price > 0;
  }

  /// Formatea un precio para mostrar en la UI
  /// Si el precio es 0 o null, muestra "No asignado"
  static String formatPriceForDisplay(
    double? price, {
    bool showCurrency = true,
  }) {
    if (price == null || price == 0) {
      return 'No asignado';
    }

    if (showCurrency) {
      return formatCurrency(price);
    }

    return formatPrice(price);
  }
}
