import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/admin_service.dart';
import '../providers/admin_mode_provider.dart';

class AdminToggle extends StatefulWidget {
  const AdminToggle({super.key});

  @override
  State<AdminToggle> createState() => _AdminToggleState();
}

class _AdminToggleState extends State<AdminToggle> {
  final AdminService _adminService = AdminService();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    // Check admin status periodically to ensure it stays updated
    _startPeriodicCheck();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await _adminService.checkAdminStatus();
    if (mounted && _isAdmin != isAdmin) {
      setState(() {
        _isAdmin = isAdmin;
      });
      
      // Also refresh the provider to ensure edit mode is synced
      final provider = Provider.of<AdminModeProvider>(context, listen: false);
      await provider.refreshAdminStatus();
      
      // Force enable edit mode for admin users
      if (isAdmin) {
        provider.forceEnableEditModeForAdmin();
      }
      
      debugPrint('AdminToggle: Admin status changed to: $isAdmin');
    }
  }

  void _startPeriodicCheck() {
    // Check admin status every 30 seconds to avoid excessive calls
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        _checkAdminStatus();
        _startPeriodicCheck();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminModeProvider>(
      builder: (context, adminProvider, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: adminProvider.isEditMode 
              ? const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFFF5B041), Color(0xFFE67E22)],
                )
              : LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    const Color(0xFFF5B041).withOpacity(0.7),
                    const Color(0xFFE67E22).withOpacity(0.7),
                  ],
                ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE67E22).withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _isAdmin 
                    ? (adminProvider.isEditMode ? Icons.edit : Icons.admin_panel_settings)
                    : Icons.visibility,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isAdmin ? 'Admin Mode' : 'User Mode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),
                  if (_isAdmin)
                    Text(
                      adminProvider.isEditMode ? 'EDIT MODE ON' : 'Edit mode off',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 10,
                        fontWeight: adminProvider.isEditMode ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _isAdmin ? _showAdminOptions() : _showLoginOption(),
                child: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLoginOption() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Admin Access'),
        content: const Text('Login as admin to edit the app content in real-time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  void _showAdminOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Consumer<AdminModeProvider>(
              builder: (context, adminProvider, child) => ListTile(
                leading: Icon(
                  adminProvider.isEditMode ? Icons.edit_off : Icons.edit_note, 
                  color: adminProvider.isEditMode ? Colors.red : Colors.orange,
                ),
                title: Text(adminProvider.isEditMode ? 'Disable Edit Mode' : 'Enable Edit Mode'),
                subtitle: Text(
                  adminProvider.isEditMode 
                      ? 'Currently: Edit options are visible'
                      : 'Currently: Viewing as regular user',
                ),
                trailing: Switch(
                  value: adminProvider.isEditMode,
                  onChanged: (value) {
                    Navigator.of(context).pop();
                    _enableInAppEditing();
                  },
                  activeColor: Colors.orange,
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _enableInAppEditing();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.blue),
              title: const Text('Admin Info'),
              subtitle: const Text('How to use admin features'),
              onTap: () {
                Navigator.of(context).pop();
                _showAdminInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              subtitle: const Text('Return to user mode'),
              onTap: () {
                Navigator.of(context).pop();
                _logoutAdmin();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _enableInAppEditing() {
    final provider = Provider.of<AdminModeProvider>(context, listen: false);
    provider.toggleEditMode();
    
    // Also force refresh admin status to ensure edit mode is enabled
    provider.refreshAdminStatus();
    
    // Show informational snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              provider.isEditMode ? Icons.edit_note : Icons.visibility, 
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                provider.isEditMode 
                    ? 'Edit Mode Enabled! Long press any item to edit it.'
                    : 'Edit Mode Disabled. You\'re viewing as a regular user.',
              ),
            ),
          ],
        ),
        backgroundColor: provider.isEditMode ? Colors.orange : Colors.grey,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logoutAdmin() async {
    try {
      await _adminService.logoutAdmin();
      Provider.of<AdminModeProvider>(context, listen: false).disableEditMode();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.logout, color: Colors.white),
                SizedBox(width: 8),
                Text('Logged out successfully. Returned to user mode.'),
              ],
            ),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Force refresh admin status
        await _checkAdminStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _showAdminInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 8),
            Text('Admin Mode Active'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('You are in Admin Mode. You can:'),
            SizedBox(height: 8),
            Text('• Enable edit mode to edit items'),
            Text('• Long press any item to edit it'),
            Text('• Tap edit icons to modify content'),
            Text('• Delete items directly from the app'),
            Text('• See the app exactly as users do'),
            SizedBox(height: 12),
            Text(
              'Note: Long press any food item, deal, or restaurant to start editing directly in the app.',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it!'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _enableInAppEditing();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enable Edit Mode'),
          ),
        ],
      ),
    );
  }
}
