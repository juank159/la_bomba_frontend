import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

/// Picks a product photo and compresses it before it ever leaves the
/// device: the backend stores it as base64 directly in the database (no
/// file storage available on Render's ephemeral filesystem), so keeping
/// each photo small matters both for upload speed and for how much the
/// catalog list payload grows as photos are added.
class VegetableImageService {
  static const int _maxDimension = 500;
  static const int _jpegQuality = 80;

  final ImagePicker _picker = ImagePicker();

  /// Opens the system photo picker, resizes the image so its longest side
  /// is at most [_maxDimension]px, re-encodes it as JPEG and returns it as
  /// a base64 string (no "data:image/...;base64," prefix). Returns null if
  /// the user cancelled or the file couldn't be decoded as an image.
  Future<String?> pickAndCompress() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxDimension.toDouble(),
      maxHeight: _maxDimension.toDouble(),
      imageQuality: _jpegQuality,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    return compress(bytes);
  }

  /// Resizes/re-encodes raw image bytes and returns them as base64. Exposed
  /// separately from [pickAndCompress] so it can be unit tested without a
  /// real file picker.
  String? compress(List<int> bytes) {
    final decoded = img.decodeImage(bytes is Uint8List ? bytes : Uint8List.fromList(bytes));
    if (decoded == null) return null;

    final needsResize = decoded.width > _maxDimension || decoded.height > _maxDimension;
    final resized = needsResize
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? _maxDimension : null,
            height: decoded.height > decoded.width ? _maxDimension : null,
          )
        : decoded;

    final jpg = img.encodeJpg(resized, quality: _jpegQuality);
    return base64Encode(jpg);
  }
}
