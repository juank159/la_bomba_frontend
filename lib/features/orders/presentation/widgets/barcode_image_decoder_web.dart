import 'dart:js_interop';

/// Definida en web/index.html: mobile_scanner no soporta analyzeImage() en
/// web, así que la imagen se lee con BarcodeDetector o ZXing del navegador.
@JS('laBombaDecodeBarcode')
external JSPromise<JSString?> _decodeBarcode(JSString url);

Future<String?> decodeBarcodeFromImageUrl(String url) async {
  final result = await _decodeBarcode(url.toJS).toDart;
  return result?.toDart;
}
