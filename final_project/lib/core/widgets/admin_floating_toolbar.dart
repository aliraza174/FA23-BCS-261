import 'package:flutter/material.dart';
import '../providers/admin_mode_provider.dart';

class AdminFloatingToolbar extends StatefulWidget {
  const AdminFloatingToolbar({super.key});

  @override
  State<AdminFloatingToolbar> createState() => _AdminFloatingToolbarState();
}

class _AdminFloatingToolbarState extends State<AdminFloatingToolbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;
  final AdminModeProvider _adminProvider = AdminModeProvider();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleToolbar() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _adminProvider,
      builder: (context, child) {
        if (!_adminProvider.isAdmin) return const SizedBox.shrink();

        return Stack(
          children: [
            // Prominent edit mode banner at top
            if (_adminProvider.isEditMode)
              Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_note, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '🔥 EDIT MODE ACTIVE - TAP EDIT BUTTONS TO MODIFY CONTENT',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Original floating toolbar
            Positioned(
              bottom: 100,
              right: 16,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                  if (_isExpanded) ...[
                    _buildToolbarButton(
                      icon: _adminProvider.showEditOverlays
                          ? Icons.edit_off
                          : Icons.edit,
                      label: _adminProvider.showEditOverlays
                          ? 'Hide Overlays'
                          : 'Show Overlays',
                      onTap: () {
                        _adminProvider.toggleEditOverlays();
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildToolbarButton(
                      icon: _adminProvider.isEditMode
                          ? Icons.preview
                          : Icons.edit_note,
                      label: _adminProvider.isEditMode
                          ? 'Exit Edit Mode'
                          : 'Enter Edit Mode',
                      onTap: () {
                        _adminProvider.toggleEditMode();
                        _showEditModeInfo();
                      },
                    ),
                    const SizedBox(height: 8),
                  ],
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    onPressed: _toggleToolbar,
                    child: AnimatedRotation(
                      turns: _isExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.admin_panel_settings),
                    ),
                  ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(_animation),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditModeInfo() {
    if (!_adminProvider.isEditMode) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Edit Mode Active: Long press items to edit them',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}