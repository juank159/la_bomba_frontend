// lib/app/core/services/pdf_service_web.dart
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

/// Share or download PDF file in web platform
Future<void> sharePdf(
  Uint8List pdfData,
  String filename, {
  String? text,
  String? subject,
}) async {
  try {
    // Check if Web Share API is available
    if (_canShare()) {
      await _sharePdfUsingWebShareAPI(pdfData, filename, text: text);
    } else {
      // Fallback to download
      downloadPdf(pdfData, filename);
    }
  } catch (e) {
    // If sharing fails, fallback to download
    downloadPdf(pdfData, filename);
  }
}

/// Download PDF file in web platform (fallback when sharing is not available)
void downloadPdf(Uint8List pdfData, String filename) {
  final blob = _buildPdfBlob(pdfData);
  final url = web.URL.createObjectURL(blob);
  web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..click();
  web.URL.revokeObjectURL(url);
}

web.Blob _buildPdfBlob(Uint8List pdfData) {
  return web.Blob(
    <JSAny>[pdfData.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
}

/// Check if Web Share API is available
bool _canShare() {
  try {
    return web.window.navigator.has('share');
  } catch (e) {
    return false;
  }
}

/// Share PDF using Web Share API
Future<void> _sharePdfUsingWebShareAPI(
  Uint8List pdfData,
  String filename, {
  String? text,
}) async {
  try {
    final blob = _buildPdfBlob(pdfData);
    final file = web.File(
      <JSAny>[blob].toJS,
      filename,
      web.FilePropertyBag(type: 'application/pdf'),
    );

    final shareData = web.ShareData(
      files: <web.File>[file].toJS,
      text: text ?? '',
    );

    final navigator = web.window.navigator;

    if (navigator.canShare(shareData)) {
      await navigator.share(shareData).toDart;
    } else {
      // Files not supported, fallback to download
      downloadPdf(pdfData, filename);
    }
  } catch (e) {
    // If sharing fails, fallback to download
    downloadPdf(pdfData, filename);
  }
}
