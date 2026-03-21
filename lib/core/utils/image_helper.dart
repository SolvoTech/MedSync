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

      // Keep compression output in the same directory with a stable extension.
      final absolutePath = file.absolute.path;
      final separatorIndex = absolutePath.lastIndexOf(Platform.pathSeparator);
      final dotIndex = absolutePath.lastIndexOf('.');
      final hasExtension = dotIndex > separatorIndex;
      final basePath = hasExtension
          ? absolutePath.substring(0, dotIndex)
          : absolutePath;
      final extension = hasExtension
          ? absolutePath.substring(dotIndex).toLowerCase()
          : '.jpg';
      final targetPath = '${basePath}_compressed$extension';

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: quality,
        minWidth: minWidth,
        minHeight: minHeight,
      );

      if (compressedFile == null) {
        // Fallback to original if compression fails.
        return file;
      }

      return File(compressedFile.path);
    } catch (e) {
      return null;
    }
  }
}
