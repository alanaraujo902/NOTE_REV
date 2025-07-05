import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  // Pick image from gallery or camera
  Future<String?> pickImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image == null) return null;

      // Save image to app directory
      final String savedPath = await _saveImageToAppDirectory(image);
      return savedPath;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  // Save image to app's documents directory
  Future<String> _saveImageToAppDirectory(XFile image) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = path.join(appDir.path, 'images');
    
    // Create images directory if it doesn't exist
    final Directory imagesDirObj = Directory(imagesDir);
    if (!await imagesDirObj.exists()) {
      await imagesDirObj.create(recursive: true);
    }

    // Generate unique filename
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final String extension = path.extension(image.path);
    final String fileName = 'image_$timestamp$extension';
    final String savedPath = path.join(imagesDir, fileName);

    // Copy image to app directory
    final File imageFile = File(image.path);
    await imageFile.copy(savedPath);

    return savedPath;
  }

  // Delete image file
  Future<bool> deleteImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  // Check if image file exists
  Future<bool> imageExists(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      return await imageFile.exists();
    } catch (e) {
      return false;
    }
  }

  // Get image file size
  Future<int> getImageSize(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        return await imageFile.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<String> savePngFromBytes(Uint8List bytes) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imagesDir = path.join(appDir.path, 'snapshots');
    final Directory dir = Directory(imagesDir);
    if (!await dir.exists()) await dir.create(recursive: true);

    final String fileName = 'snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
    final String filePath = path.join(imagesDir, fileName);
    final File imageFile = File(filePath);
    await imageFile.writeAsBytes(bytes);
    return filePath;
  }

}

