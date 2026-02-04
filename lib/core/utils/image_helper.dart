import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

/// Image picking and processing utilities
class ImageHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: AppConstants.imageQuality,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw ImageException('Failed to pick image from gallery');
    }
  }

  /// Pick image from camera
  static Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: AppConstants.imageQuality,
      );

      if (image == null) return null;

      return File(image.path);
    } catch (e) {
      throw ImageException('Failed to capture image from camera');
    }
  }

  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImages({int maxImages = 10}) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: AppConstants.imageQuality,
      );

      if (images.length > maxImages) {
        throw ImageException('You can only select up to $maxImages images');
      }

      return images.map((xFile) => File(xFile.path)).toList();
    } catch (e) {
      throw ImageException('Failed to pick multiple images');
    }
  }

  /// Compress image
  static Future<File> compressImage(File file) async {
    try {
      final bytes = await file.readAsBytes();

      // Check file size
      if (bytes.lengthInBytes > AppConstants.maxImageUploadSize) {
        // Decode image
        img.Image? image = img.decodeImage(bytes);
        if (image == null) {
          throw ImageException('Failed to decode image');
        }

        // Resize if necessary
        if (image.width > 1920 || image.height > 1920) {
          image = img.copyResize(
            image,
            width: image.width > image.height ? 1920 : null,
            height: image.height > image.width ? 1920 : null,
          );
        }

        // Compress
        final compressed = img.encodeJpg(
          image,
          quality: AppConstants.imageQuality,
        );

        // Save compressed image
        final compressedFile = File(file.path);
        await compressedFile.writeAsBytes(compressed);

        return compressedFile;
      }

      return file;
    } catch (e) {
      throw ImageException('Failed to compress image');
    }
  }

  /// Create thumbnail
  static Future<File> createThumbnail(File file) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw ImageException('Failed to decode image');
      }

      // Resize to thumbnail
      final thumbnail = img.copyResize(
        image,
        width: AppConstants.thumbnailSize,
      );

      // Encode
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: 85);

      // Save thumbnail
      final thumbnailPath = file.path.replaceAll('.jpg', '_thumb.jpg');
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);

      return thumbnailFile;
    } catch (e) {
      throw ImageException('Failed to create thumbnail');
    }
  }

  /// Validate image file
  static bool validateImageFile(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp'].contains(ext);
  }

  /// Get image size in bytes
  static Future<int> getImageSize(File file) async {
    return await file.length();
  }
}
