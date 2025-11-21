import 'dart:typed_data';

/// Placeholder for mobile - actual sharing is done via path_provider + share_plus
Future<void> sharePdf(Uint8List pdfData, String filename, {String? text, String? subject}) async {
  // This is never called on mobile, but needs to exist for compilation
  throw UnimplementedError('Use shareOrderPdf for mobile platforms');
}

/// Placeholder for mobile
void downloadPdf(Uint8List pdfData, String filename) {
  // This is never called on mobile, but needs to exist for compilation
  throw UnimplementedError('Use shareOrderPdf for mobile platforms');
}
