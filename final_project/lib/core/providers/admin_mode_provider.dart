import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/admin_service.dart';

class AdminModeProvider with ChangeNotifier {
  static final AdminModeProvider _instance = AdminModeProvider._internal();
  factory AdminModeProvider() => _instance;
  AdminModeProvider._internal();

  final AdminService _adminService = AdminService();
  bool _isAdmin = false;
  bool _showEditOverlays = true;
  bool _isEditMode = false;
  bool _isInitialized = false;

  bool get isAdmin => _isAdmin;
  bool get isAdminLoggedIn => _isAdmin; // Added missing getter
  bool get showEditOverlays => _showEditOverlays && _isAdmin;
  bool get isEditMode => _isEditMode && _isAdmin;
  bool get isEditModeEnabled => _isEditMode && _isAdmin; // Added missing getter

  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations
    
    try {
      // Ensure admin service is initialized first
      await _adminService.initialize();
      _isAdmin = await _adminService.checkAdminStatus();
      
      // Automatically enable edit mode when admin is logged in
      if (_isAdmin) {
        _isEditMode = true;
        debugPrint('AdminModeProvider: Auto-enabled edit mode for admin');
      }
      
      _isInitialized = true;
      debugPrint('AdminModeProvider initialized: isAdmin=$_isAdmin, editMode=$_isEditMode');
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing AdminModeProvider: $e');
    }
  }

  void toggleEditOverlays() {
    _showEditOverlays = !_showEditOverlays;
    notifyListeners();
  }

  void toggleEditMode() {
    _isEditMode = !_isEditMode;
    notifyListeners();
  }

  void enableEditMode() {
    _isEditMode = true;
    notifyListeners();
  }

  void disableEditMode() {
    _isEditMode = false;
    notifyListeners();
  }

  void forceEnableEditModeForAdmin() {
    if (_isAdmin) {
      _isEditMode = true;
      debugPrint('AdminModeProvider: Force enabled edit mode for admin user');
      notifyListeners();
    }
  }

  Future<void> refreshAdminStatus() async {
    final wasAdmin = _isAdmin;
    _isAdmin = await _adminService.checkAdminStatus();
    
    // Auto-enable edit mode whenever admin is logged in
    if (_isAdmin) {
      _isEditMode = true;
      debugPrint('AdminModeProvider: Auto-enabled edit mode for admin (status refresh)');
    } else {
      _isEditMode = false;
      debugPrint('AdminModeProvider: Disabled edit mode for admin logout');
    }
    
    notifyListeners();
  }
}