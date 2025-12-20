import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'admin_auth_service.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final AdminAuthService _authService = AdminAuthService();
  bool? _isAdmin;
  String? _currentUserId;

  bool get isAdmin => _isAdmin ?? false;
  String? get currentUserId => _currentUserId;
  bool get isLoggedIn => _authService.isAuthenticated;

  Future<bool> checkAdminStatus() async {
    try {
      // Check if admin is authenticated via our auth service
      await _authService.initialize(); // Ensure auth service is initialized
      
      if (_authService.isAuthenticated) {
        final isValid = await _authService.isSessionValid();
        if (isValid) {
          _isAdmin = true;
          _currentUserId = _authService.currentAdminEmail;
          debugPrint('Admin status: authenticated as ${_authService.currentAdminEmail}');
          return true;
        } else {
          // Session expired, clear it
          await _authService.clearAdminSession();
        }
      }

      // Fallback: check Supabase auth if available
      final user = _supabase.auth.currentUser;
      if (user != null) {
        _isAdmin = true;
        _currentUserId = user.id;
        debugPrint('Admin status: authenticated via Supabase');
        return true;
      }

      _isAdmin = false;
      _currentUserId = null;
      return false;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      _isAdmin = false;
      return false;
    }
  }

  Future<void> clearAdminStatus() async {
    _isAdmin = false;
    _currentUserId = null;
    // Don't call clearAdminSession here to avoid infinite loop
  }

  bool _isInitialized = false;

  // Initialize both auth services
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations
    
    try {
      await _authService.initialize();
      await checkAdminStatus();
      _isInitialized = true;
      debugPrint('AdminService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AdminService: $e');
    }
  }

  // Method to authenticate admin
  Future<bool> authenticateAdmin(String email, String password) async {
    final success = await _authService.authenticateAdmin(email, password);
    if (success) {
      await checkAdminStatus();
    }
    return success;
  }

  // Method to logout admin
  Future<void> logoutAdmin() async {
    await _authService.clearAdminSession();
    await clearAdminStatus();
  }

  // Method to refresh admin session
  Future<void> refreshAdminSession() async {
    if (_authService.isAuthenticated) {
      await _authService.refreshSession();
    }
  }
}
