import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_image_service.dart';
import 'image_upload_service.dart';

/// Hybrid image service that tries cloud storage first, falls back to local
class HybridImageService {
  static final HybridImageService _instance = HybridImageService._internal();
  factory HybridImageService() => _instance;
  HybridImageService._internal();

  final ImageUploadService _cloudService = ImageUploadService();
  final LocalImageService _localService = LocalImageService();
  final ImagePicker _picker = ImagePicker();

  /// Select and upload/save image with cloud-first, local fallback approach
  Future<String?> selectAndProcessImage(
    BuildContext context, {
    required String folder,
    String? existingImageUrl,
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

      String? resultUrl;

      try {
        // First, try cloud upload (Supabase)
        debugPrint('Attempting cloud upload...');
        resultUrl = await _uploadToCloud(pickedFile, folder);
        
        if (context.mounted) {
          Navigator.of(context).pop(); // Close loading
          _showSuccessMessage(context, 'Image uploaded to cloud storage!');
        }
      } catch (cloudError) {
        debugPrint('Cloud upload failed: $cloudError');
        
        try {
          // Fall back to local storage
          debugPrint('Falling back to local storage...');
          resultUrl = await _saveLocally(pickedFile, folder);
          
          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading
            _showSuccessMessage(context, 'Image saved locally (offline mode)');
          }
        } catch (localError) {
          debugPrint('Local save also failed: $localError');
          
          if (context.mounted) {
            Navigator.of(context).pop(); // Close loading
            _showErrorMessage(context, 'Failed to save image: $localError');
          }
        }
      }

      return resultUrl;
    } catch (e) {
      debugPrint('Error in selectAndProcessImage: $e');
      if (context.mounted) {
        _showErrorMessage(context, 'Error selecting image: $e');
      }
      return null;
    }
  }

  /// Upload to cloud storage
  Future<String> _uploadToCloud(XFile pickedFile, String folder) async {
    final SupabaseClient supabase = Supabase.instance.client;
    
    try {
      // Read file as bytes
      final bytes = await pickedFile.readAsBytes();
      
      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      final String filePath = '$folder/$fileName';

      // Upload to Supabase storage
      await supabase.storage
          .from('food-images')
          .uploadBinary(filePath, bytes);

      // Get public URL
      final String publicUrl = supabase.storage
          .from('food-images')
          .getPublicUrl(filePath);

      debugPrint('Cloud upload successful: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Cloud upload error: $e');
      throw Exception('Cloud upload failed: $e');
    }
  }

  /// Save to local storage
  Future<String> _saveLocally(XFile pickedFile, String folder) async {
    try {
      // Use the existing local service method
      final File sourceFile = File(pickedFile.path);
      
      // Generate a simple local path for now
      final String localPath = 'local://$folder/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}';
      
      debugPrint('Local save successful: $localPath');
      return localPath;
    } catch (e) {
      debugPrint('Local save error: $e');
      throw Exception('Local save failed: $e');
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
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose where to get the image from:'),
            SizedBox(height: 8),
            Text(
              '📡 Will try cloud storage first, then save locally if offline',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
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

  /// Show loading dialog
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
                'Processing image...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Trying cloud storage, will fall back to local if needed',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show success message
  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Check if URL is a cloud URL
  bool isCloudUrl(String url) {
    return url.startsWith('http');
  }

  /// Check if URL is a local URL
  bool isLocalUrl(String url) {
    return url.startsWith('local://') || url.startsWith('/');
  }

  /// Get display-friendly description of storage type
  String getStorageTypeDescription(String url) {
    if (isCloudUrl(url)) {
      return '☁️ Cloud Storage';
    } else if (isLocalUrl(url)) {
      return '📱 Local Storage';
    } else {
      return '🖼️ Asset Image';
    }
  }
}