/// Constantes para los nombres y etiquetas de precios
/// Mantiene uniformidad en toda la aplicación
class PriceConstants {
  // Nombres de precios para mostrar en UI
  static const String priceALabel = 'Público';
  static const String priceBLabel = 'Mayor';
  static const String priceCLabel = 'Super';
  
  // Nombres técnicos de campos
  static const String priceAField = 'precioA';
  static const String priceBField = 'precioB';
  static const String priceCField = 'precioC';
  
  /// Obtiene el nombre de display para un campo de precio
  static String getDisplayName(String field) {
    switch (field) {
      case priceAField:
        return priceALabel;
      case priceBField:
        return priceBLabel;
      case priceCField:
        return priceCLabel;
      default:
        return field;
    }
  }
  
  /// Obtiene el campo técnico desde el nombre de display
  static String getFieldName(String displayName) {
    switch (displayName) {
      case priceALabel:
        return priceAField;
      case priceBLabel:
        return priceBField;
      case priceCLabel:
        return priceCField;
      default:
        return displayName;
    }
  }
  
  /// Mapa de todos los precios con sus etiquetas
  static const Map<String, String> priceLabels = {
    priceAField: priceALabel,
    priceBField: priceBLabel,
    priceCField: priceCLabel,
  };
}