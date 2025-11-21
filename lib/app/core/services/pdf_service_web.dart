// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:js_util' as js_util;

/// Share or download PDF file in web platform
Future<void> sharePdf(Uint8List pdfData, String filename, {String? text, String? subject}) async {
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
  final blob = html.Blob([pdfData], 'application/pdf');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}

/// Check if Web Share API is available
bool _canShare() {
  try {
    return js_util.hasProperty(html.window.navigator, 'share');
  } catch (e) {
    return false;
  }
}

/// Share PDF using Web Share API
Future<void> _sharePdfUsingWebShareAPI(Uint8List pdfData, String filename, {String? text}) async {
  try {
    final blob = html.Blob([pdfData], 'application/pdf');
    final file = html.File([blob], filename, {'type': 'application/pdf'});

    final shareData = {
      'files': [file],
      if (text != null) 'text': text,
    };

    // Check if files can be shared
    final navigator = html.window.navigator;
    final canShareFiles = js_util.callMethod<bool>(
      navigator,
      'canShare',
      [js_util.jsify(shareData)],
    );

    if (canShareFiles) {
      await js_util.promiseToFuture(
        js_util.callMethod(navigator, 'share', [js_util.jsify(shareData)]),
      );
    } else {
      // Files not supported, try sharing just text with download link
      downloadPdf(pdfData, filename);
    }
  } catch (e) {
    // If sharing fails, fallback to download
    downloadPdf(pdfData, filename);
  }
}
