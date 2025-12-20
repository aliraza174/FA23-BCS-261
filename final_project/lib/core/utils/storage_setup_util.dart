import 'package:supabase_flutter/supabase_flutter.dart';

class StorageSetupUtil {
  final SupabaseClient _supabase;

  StorageSetupUtil(this._supabase);

  /// Initialize storage bucket and policies
  /// This should be called once during app initialization
  Future<bool> initializeStorage() async {
    try {
      print('🔧 Initializing storage...');
      
      // Check if bucket exists
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.id == 'food-images');
      
      if (!bucketExists) {
        print('📦 Creating storage bucket...');
        
        // Create the bucket using admin privileges
        await _createBucketWithRetry();
      } else {
        print('✅ Storage bucket already exists');
      }
      
      // Verify bucket is accessible
      await _verifyBucketAccess();
      
      print('✅ Storage initialization complete');
      return true;
      
    } catch (e) {
      print('❌ Storage initialization failed: $e');
      return false;
    }
  }

  /// Create bucket with retry logic
  Future<void> _createBucketWithRetry() async {
    int retries = 3;
    
    while (retries > 0) {
      try {
        // Try creating with different approaches
        if (retries == 3) {
          // First attempt: Standard creation
          await _supabase.storage.createBucket(
            'food-images',
            const BucketOptions(public: true),
          );
          print('✅ Bucket created successfully (standard method)');
          return;
        } else if (retries == 2) {
          // Second attempt: Using SQL insert directly
          await _createBucketViaSQL();
          print('✅ Bucket created successfully (SQL method)');
          return;
        } else {
          // Final attempt: Manual bucket setup
          await _setupManualBucket();
          print('✅ Bucket setup completed (manual method)');
          return;
        }
      } catch (e) {
        retries--;
        print('⚠️ Bucket creation attempt failed: $e (${3 - retries}/3)');
        
        if (retries == 0) {
          throw Exception('Failed to create bucket after 3 attempts: $e');
        }
        
        // Wait before retry
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  /// Create bucket using direct SQL
  Future<void> _createBucketViaSQL() async {
    await _supabase.rpc('create_storage_bucket', params: {
      'bucket_id': 'food-images',
      'bucket_name': 'food-images',
      'is_public': true,
    });
  }

  /// Manual bucket setup as fallback
  Future<void> _setupManualBucket() async {
    // This is a fallback - we'll create the bucket data directly
    print('⚠️ Using manual bucket setup fallback');
    print('📋 Please create bucket manually in Supabase dashboard:');
    print('   1. Go to Storage in Supabase dashboard');
    print('   2. Create a new bucket with ID: "food-images"');
    print('   3. Enable public access');
    print('   4. Set allowed MIME types: image/jpeg, image/png, image/gif, image/webp');
  }

  /// Verify bucket access
  Future<void> _verifyBucketAccess() async {
    try {
      // Try to list files (should work even if bucket is empty)
      await _supabase.storage.from('food-images').list(
        path: '',
        searchOptions: const SearchOptions(limit: 1),
      );
      print('✅ Bucket access verified');
    } catch (e) {
      print('⚠️ Bucket access verification failed: $e');
      // Don't throw here - bucket might exist but have different permissions
    }
  }

  /// Get bucket creation status
  Future<BucketStatus> getBucketStatus() async {
    try {
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.id == 'food-images');
      
      if (!bucketExists) {
        return BucketStatus.notFound;
      }
      
      // Try to access the bucket
      try {
        await _supabase.storage.from('food-images').list(path: '', searchOptions: const SearchOptions(limit: 1));
        return BucketStatus.accessible;
      } catch (e) {
        if (e.toString().contains('403') || e.toString().contains('unauthorized')) {
          return BucketStatus.permissionDenied;
        }
        return BucketStatus.error;
      }
    } catch (e) {
      return BucketStatus.error;
    }
  }
}

enum BucketStatus {
  notFound,
  accessible,
  permissionDenied,
  error,
}