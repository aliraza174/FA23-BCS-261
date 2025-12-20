import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Show image source selection dialog (Camera vs Gallery)
  Future<String?> selectAndUploadImage(
    BuildContext context, {
    required String folder, // e.g., 'food_items', 'deals', 'restaurants'
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

      try {
        // Upload image to Supabase storage
        final String imageUrl = await _uploadToSupabase(pickedFile, folder);

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
                  Text('Image uploaded successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }

        return imageUrl;
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
                  Expanded(child: Text('Upload failed: $e')),
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
      debugPrint('Error in selectAndUploadImage: $e');
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

  /// Show loading dialog during upload
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
                'Uploading image...',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait while we upload your image',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Upload image to Supabase storage
  Future<String> _uploadToSupabase(XFile pickedFile, String folder) async {
    try {
      // Read file as bytes
      final Uint8List bytes = await pickedFile.readAsBytes();
      
      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
      final String filePath = '$folder/$fileName';

      // Upload to Supabase storage
      await _supabase.storage
          .from('food-images') // Using the correct bucket name
          .uploadBinary(filePath, bytes);

      // Get public URL
      final String publicUrl = _supabase.storage
          .from('food-images')
          .getPublicUrl(filePath);

      debugPrint('Image uploaded successfully: $publicUrl');
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
      
      // Try fallback upload method
      try {
        final File file = File(pickedFile.path);
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(pickedFile.path)}';
        final String filePath = '$folder/$fileName';

        await _supabase.storage
            .from('food-images')
            .upload(filePath, file);

        final String publicUrl = _supabase.storage
            .from('food-images')
            .getPublicUrl(filePath);

        debugPrint('Image uploaded with fallback method: $publicUrl');
        return publicUrl;
      } catch (fallbackError) {
        debugPrint('Fallback upload also failed: $fallbackError');
        throw Exception('Failed to upload image: $e');
      }
    }
  }

  /// Delete image from Supabase storage (optional cleanup)
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract file path from URL
      final Uri uri = Uri.parse(imageUrl);
      final String filePath = uri.pathSegments.skip(3).join('/'); // Skip storage/v1/object/public/bucket-name
      
      await _supabase.storage
          .from('food-images')
          .remove([filePath]);
          
      debugPrint('Image deleted successfully: $filePath');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Get optimized image URL with resize parameters
  String getOptimizedImageUrl(String originalUrl, {int? width, int? height}) {
    try {
      final Uri uri = Uri.parse(originalUrl);
      final Map<String, String> queryParams = Map.from(uri.queryParameters);
      
      if (width != null) queryParams['width'] = width.toString();
      if (height != null) queryParams['height'] = height.toString();
      queryParams['resize'] = 'contain';
      queryParams['quality'] = '80';
      
      return uri.replace(queryParameters: queryParams).toString();
    } catch (e) {
      debugPrint('Error optimizing image URL: $e');
      return originalUrl;
    }
  }
}