import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSetupHelper {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Creates an admin user and adds them to the admins table
  static Future<bool> createAdminUser({
    required String email,
    required String password,
    String role = 'admin',
  }) async {
    try {
      // First, create the user in Supabase Auth
      final AuthResponse authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        print('Failed to create auth user');
        return false;
      }

      final String userId = authResponse.user!.id;

      // Then, add them to the admins table
      await _supabase.from('admins').insert({
        'id': userId,
        'role': role,
      });

      print('Admin user created successfully: $email (ID: $userId)');
      return true;
    } catch (e) {
      print('Error creating admin user: $e');
      return false;
    }
  }

  /// Checks if the current user is an admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('admins')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Signs in as admin with email/password
  static Future<bool> signInAsAdmin(String email, String password) async {
    try {
      final AuthResponse response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) return false;

      // Verify the user is actually an admin
      return await isCurrentUserAdmin();
    } catch (e) {
      print('Admin sign in error: $e');
      return false;
    }
  }

  /// Creates storage bucket if it doesn't exist (for testing)
  static Future<bool> ensureStorageBucket() async {
    try {
      // Check if bucket exists
      final buckets = await _supabase.storage.listBuckets();
      final bucketExists = buckets.any((bucket) => bucket.id == 'public');
      
      if (!bucketExists) {
        await _supabase.storage.createBucket(
          'public',
          const BucketOptions(public: true),
        );
        print('Storage bucket created successfully');
      } else {
        print('Storage bucket already exists');
      }
      
      return true;
    } catch (e) {
      print('Error ensuring storage bucket: $e');
      return false;
    }
  }
}