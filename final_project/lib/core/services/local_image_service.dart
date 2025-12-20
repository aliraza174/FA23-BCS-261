import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// Fallback image service that stores images locally
/// Use this when Supabase storage is not available
class LocalImageService {
  static final LocalImageService _instance = LocalImageService._internal();
  factory LocalImageService() => _instance;
  LocalImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Select and save image locally, return local file path
  Future<String?> selectAndSaveImage(
    BuildContext context, {
    required String folder,
    String? existingImagePath,
  }) async {
    try {
      // Show source selection dialog
      final ImageSource? source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // Pick image from selected source
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      // Show loading dialog
      if (context.mounted) {
        _showLoadingDialog(context);
      }

      try {
        // Save image to local app directory
        final String localPath = await _saveImageLocally(pickedFile, folder);

        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Image saved successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        return localPath;
      } catch (e) {
        // Close loading dialog
        if (context.mounted) {
          Navigator.of(context).pop();
          
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Save failed: $e')),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return null;
      }
    } catch (e) {
      debugPrint('Error in selectAndSaveImage: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Show image source selection dialog
  Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_a_photo, color: Colors.orange),
            SizedBox(width: 8),
            Text('Select Image Source'),
          ],
        ),
        content: const Text('Choose where to get the image from:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.camera),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.camera_alt, size: 18),
            label: const Text('Camera'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(ImageSource.gallery),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.photo_library, size: 18),
            label: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  /// Show loading dialog during save
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Saving image...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we save your image',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save image to local app directory
  Future<String> _saveImageLocally(XFile pickedFile, String folder) async {
    try {
      // Get app directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory('${appDir.path}/images/$folder');
      
      // Create directory if it doesn't exist
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }

      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final String filePath = '${imageDir.path}/$fileName';

      // Copy file to app directory
      final File sourceFile = File(pickedFile.path);
      final File savedFile = await sourceFile.copy(filePath);

      debugPrint('Image saved locally: ${savedFile.path}');
      return savedFile.path;
    } catch (e) {
      debugPrint('Error saving image locally: $e');
      throw Exception('Failed to save image: $e');
    }
  }

  /// Delete local image file
  Future<bool> deleteLocalImage(String imagePath) async {
    try {
      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('Local image deleted: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting local image: $e');
      return false;
    }
  }

  /// Check if file is a local image path
  bool isLocalImage(String imagePath) {
    return imagePath.startsWith('/') || imagePath.contains('Documents');
  }

  /// Get all images in a folder
  Future<List<String>> getImagesInFolder(String folder) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory('${appDir.path}/images/$folder');
      
      if (!await imageDir.exists()) {
        return [];
      }

      final List<FileSystemEntity> files = await imageDir.list().toList();
      final List<String> imagePaths = [];

      for (final file in files) {
        if (file is File && _isImageFile(file.path)) {
          imagePaths.add(file.path);
        }
      }

      return imagePaths;
    } catch (e) {
      debugPrint('Error getting images in folder: $e');
      return [];
    }
  }

  /// Check if file is an image based on extension
  bool _isImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// Clean up old images (optional)
  Future<void> cleanupOldImages({int daysOld = 30}) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory imageDir = Directory('${appDir.path}/images');
      
      if (!await imageDir.exists()) return;

      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      final List<FileSystemEntity> files = await imageDir.list(recursive: true).toList();

      for (final file in files) {
        if (file is File) {
          final FileStat stat = await file.stat();
          if (stat.modified.isBefore(cutoffDate)) {
            await file.delete();
            debugPrint('Deleted old image: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up old images: $e');
    }
  }
}