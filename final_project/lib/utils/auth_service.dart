import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Admin credentials - in production, store securely
  static const String adminEmail = 'admin@torbaaz.com';
  static const String adminPassword = 'TorbaazAdmin@707';

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Check if user is admin
  bool get isAdmin => currentUser?.email == adminEmail;

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password, {bool checkAdminCredentials = true}) async {
    try {
      // First check hardcoded admin credentials if requested
      if (checkAdminCredentials && 
          email.toLowerCase().trim() == adminEmail.toLowerCase() && 
          password == adminPassword) {
        debugPrint('✅ Admin authenticated with hardcoded credentials (AuthService)');
        return true;
      }
      
      // Fall back to Supabase authentication
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (response.user != null) {
        debugPrint('✅ User authenticated via Supabase');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error signing in (Supabase): ${e.toString()}');
      // If Supabase fails but we're checking admin credentials, try admin check
      if (checkAdminCredentials && 
          email.toLowerCase().trim() == adminEmail.toLowerCase() && 
          password == adminPassword) {
        debugPrint('✅ Fallback admin authentication successful');
        return true;
      }
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  // Get user's email
  String? get userEmail => currentUser?.email ?? adminEmail;

  // Check if user has admin role from Supabase
  Future<bool> hasAdminRole() async {
    try {
      if (currentUser == null) return false;

      final response = await _supabase
          .from('user_roles')
          .select('role')
          .eq('user_id', currentUser!.id)
          .single();

      return response['role'] == 'admin';
    } catch (e) {
      debugPrint('Error checking admin role: $e');
      // Fall back to email check if the query fails
      return isAdmin;
    }
  }
}