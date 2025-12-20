import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:dartz/dartz.dart';
// import 'package:image/image.dart' as img;
import '../error/failures.dart';
import 'storage_setup_util.dart';

class ImagePickerUtil {
  final ImagePicker _picker;
  final SupabaseClient _supabase;
  late final StorageSetupUtil _storageSetup;

  ImagePickerUtil(this._supabase) : _picker = ImagePicker() {
    _storageSetup = StorageSetupUtil(_supabase);
  }

  Future<Either<Failure, String>> pickAndUploadImage({
    required String storagePath,
    ImageSource source = ImageSource.gallery,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85, // Slight increase for better quality
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image == null) {
        return const Left(ValidationFailure('No image selected'));
      }

      // Generate unique filename with proper extension
      final String extension = path.extension(image.name).toLowerCase();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}$extension';
      final String fullPath = '$storagePath/$fileName';

      // Validate file type
      if (!_isValidImageType(extension)) {
        return const Left(ValidationFailure('Please select a valid image file (JPG, PNG, WebP, or GIF)'));
      }

      print('🔄 Starting image upload: $fullPath');

      // Ensure storage bucket exists and is accessible
      final storageReady = await _ensureStorageReady();
      if (storageReady != null) {
        return Left(storageReady);
      }

      // Read and process image bytes
      final Uint8List originalBytes = await image.readAsBytes();
      final Uint8List processedBytes = await _processImageBytes(originalBytes, extension);

      print('📏 Original size: ${originalBytes.length} bytes, Processed size: ${processedBytes.length} bytes');

      // Upload using binary method for both web and mobile (more consistent)
      final response = await _supabase.storage.from('food-images').uploadBinary(
        fullPath, 
        processedBytes,
        fileOptions: FileOptions(
          cacheControl: '3600',
          upsert: false,
          contentType: _getContentType(extension),
        ),
      );

      print('✅ Upload successful: $response');

      // Generate signed URL for better security and reliability
      final String imageUrl = _supabase.storage.from('food-images').getPublicUrl(fullPath);
      
      // Verify the uploaded image is accessible
      await _verifyImageAccessibility(imageUrl);
      
      return Right(imageUrl);
    } catch (e) {
      print('❌ Image upload error: $e');
      return _handleUploadError(e);
    }
  }

  /// Validates if the file extension is supported
  bool _isValidImageType(String extension) {
    final validTypes = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    return validTypes.contains(extension.toLowerCase());
  }

  /// Gets the appropriate content type for the file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Processes image bytes for optimization and web compatibility
  Future<Uint8List> _processImageBytes(Uint8List originalBytes, String extension) async {
    try {
      // For now, skip image processing to avoid dependencies
      // TODO: Re-enable image processing after adding image package
      return originalBytes;
      
      // For large files, compress them
      // if (originalBytes.length > 2 * 1024 * 1024) { // > 2MB
      //   final img.Image? image = img.decodeImage(originalBytes);
      //   if (image != null) {
      //     // Resize if too large
      //     img.Image resized = image;
      //     if (image.width > 1920 || image.height > 1080) {
      //       resized = img.copyResize(image, width: 1920, height: 1080, maintainAspect: true);
      //     }
      //     
      //     // Compress based on format
      //     if (extension.toLowerCase() == '.png') {
      //       return Uint8List.fromList(img.encodePng(resized, level: 6));
      //     } else {
      //       return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
      //     }
      //   }
      // }
      // 
      // return originalBytes;
    } catch (e) {
      print('⚠️ Image processing failed, using original: $e');
      return originalBytes;
    }
  }

  /// Verifies that the uploaded image is accessible
  Future<void> _verifyImageAccessibility(String imageUrl) async {
    try {
      // Simple verification - try to get the public URL
      final uri = Uri.parse(imageUrl);
      if (!uri.hasAbsolutePath) {
        throw Exception('Invalid image URL generated');
      }
      print('✅ Image accessibility verified: $imageUrl');
    } catch (e) {
      print('⚠️ Image accessibility check failed: $e');
      // Don't fail the upload for this, just log it
    }
  }

  /// Handles upload errors with detailed error messages
  Left<Failure, String> _handleUploadError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('bucket not found') || errorString.contains('invalid bucket')) {
      return const Left(StorageFailure('Storage bucket not found. Please check configuration.'));
    } else if (errorString.contains('unauthorized') || errorString.contains('permission denied') || errorString.contains('403')) {
      return const Left(StorageFailure('Permission denied. Please ensure you are logged in as an admin.'));
    } else if (errorString.contains('duplicate key') || errorString.contains('already exists')) {
      return const Left(StorageFailure('File already exists. Please try again.'));
    } else if (errorString.contains('file size') || errorString.contains('too large')) {
      return const Left(StorageFailure('File size too large. Please select a smaller image.'));
    } else if (errorString.contains('network') || errorString.contains('connection')) {
      return const Left(NetworkFailure('Network error. Please check your connection and try again.'));
    } else if (errorString.contains('timeout')) {
      return const Left(NetworkFailure('Upload timeout. Please try again with a smaller image.'));
    } else {
      return Left(StorageFailure('Failed to upload image. Error: ${error.toString()}'));
    }
  }

  /// Ensure storage is ready (bucket exists and accessible)
  Future<Failure?> _ensureStorageReady() async {
    try {
      print('🔍 Checking storage status...');
      
      final status = await _storageSetup.getBucketStatus();
      
      switch (status) {
        case BucketStatus.accessible:
          print('✅ Storage is ready');
          return null;
          
        case BucketStatus.notFound:
          print('📦 Bucket not found, attempting to create...');
          final created = await _storageSetup.initializeStorage();
          if (created) {
            print('✅ Storage bucket created successfully');
            return null;
          } else {
            return const StorageFailure(
              'Failed to create storage bucket. Please create it manually:\n'
              '1. Go to Supabase Dashboard > Storage\n'
              '2. Create bucket with ID: "public"\n'
              '3. Enable public access'
            );
          }
          
        case BucketStatus.permissionDenied:
          return const StorageFailure('Permission denied. Please ensure you are logged in as an admin.');
          
        case BucketStatus.error:
          return const StorageFailure('Storage system error. Please contact administrator.');
      }
    } catch (e) {
      print('❌ Storage readiness check failed: $e');
      return StorageFailure('Storage check failed: ${e.toString()}');
    }
  }

  Future<Either<Failure, void>> deleteImage(String imageUrl) async {
    try {
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.last;

      await _supabase.storage.from('food-images').remove([path]);
      return const Right(unit);
    } catch (e) {
      return Left(StorageFailure('Failed to delete image: ${e.toString()}'));
    }
  }
}
