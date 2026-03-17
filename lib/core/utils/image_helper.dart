import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Picks an image from the given [source] (camera or gallery)
  /// and compresses it. Returns the compressed file or null.
  static Future<File?> pickAndCompressImage(
    ImageSource source, {
    int quality = 80,
    int minWidth = 800,
    int minHeight = 800,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return null;

      final file = File(pickedFile.path);
      
      // Get target path for compressed file (append _compressed to filename)
      final lastIndex = file.absolute.path.lastIndexOf(RegExp(r'.jp|.png'));
      final splitted = file.absolute.path.substring(0, (lastIndex >= 0 ? lastIndex : file.absolute.path.length));
      final extension = lastIndex >= 0 ? file.absolute.path.substring(lastIndex) : '.jpeg';
      final targetPath = '${splitted}_compressed$extension';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );

      if (compressedFile == null) return file; // Fallback to original if compression fails
      
      return File(compressedFile.path);
    } catch (e) {
      return null;
    }
  }
}
