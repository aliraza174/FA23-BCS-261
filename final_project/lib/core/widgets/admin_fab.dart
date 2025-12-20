import 'package:flutter/material.dart';
import '../providers/admin_mode_provider.dart';
import 'admin_create_overlay.dart';
import 'package:provider/provider.dart';

/// Universal Floating Action Button for admin create functionality
/// Shows only when admin is logged in and edit mode is active
class AdminFAB extends StatelessWidget {
  final String itemType;
  final Function(String itemType, Map<String, dynamic> newItem)? onItemCreated;

  const AdminFAB({
    super.key,
    required this.itemType,
    this.onItemCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminModeProvider>(
      builder: (context, adminProvider, child) {
        // Only show FAB if admin is logged in and edit mode is active
        if (!adminProvider.isAdminLoggedIn || !adminProvider.isEditModeEnabled) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton.extended(
          onPressed: () => _showCreateDialog(context),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 8,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 20),
              const SizedBox(width: 8),
              Text(
                _getButtonText(),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          heroTag: 'admin_fab_$itemType', // Unique hero tag to avoid conflicts
        );
      },
    );
  }

  String _getButtonText() {
    switch (itemType) {
      case 'food_items':
        return 'Add Food Item';
      case 'deals':
        return 'Add Deal';
      case 'restaurants':
        return 'Add Restaurant';
      case 'menu_categories':
        return 'Add Category';
      default:
        return 'Add Item';
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminCreateOverlay(
        itemType: itemType,
        onCreate: (itemType, newItem) {
          // Call the callback function if provided
          onItemCreated?.call(itemType, newItem);
        },
      ),
    );
  }
}

/// Alternative minimal FAB for pages with limited space
class AdminMiniAdminFAB extends StatelessWidget {
  final String itemType;
  final Function(String itemType, Map<String, dynamic> newItem)? onItemCreated;
  final String? tooltip;

  const AdminMiniAdminFAB({
    super.key,
    required this.itemType,
    this.onItemCreated,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminModeProvider>(
      builder: (context, adminProvider, child) {
        // Only show FAB if admin is logged in and edit mode is active
        if (!adminProvider.isAdminLoggedIn || !adminProvider.isEditModeEnabled) {
          return const SizedBox.shrink();
        }

        return FloatingActionButton(
          onPressed: () => _showCreateDialog(context),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 6,
          tooltip: tooltip ?? _getTooltip(),
          heroTag: 'admin_mini_fab_$itemType', // Unique hero tag
          child: const Icon(Icons.add, size: 24),
        );
      },
    );
  }

  String _getTooltip() {
    switch (itemType) {
      case 'food_items':
        return 'Add New Food Item';
      case 'deals':
        return 'Add New Deal';
      case 'restaurants':
        return 'Add New Restaurant';
      case 'menu_categories':
        return 'Add New Category';
      default:
        return 'Add New Item';
    }
  }

  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminCreateOverlay(
        itemType: itemType,
        onCreate: (itemType, newItem) {
          // Call the callback function if provided
          onItemCreated?.call(itemType, newItem);
        },
      ),
    );
  }
}

/// Speed dial FAB for pages that need multiple create options
class AdminSpeedDialFAB extends StatefulWidget {
  final List<SpeedDialAction> actions;
  
  const AdminSpeedDialFAB({
    super.key,
    required this.actions,
  });

  @override
  State<AdminSpeedDialFAB> createState() => _AdminSpeedDialFABState();
}

class _AdminSpeedDialFABState extends State<AdminSpeedDialFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminModeProvider>(
      builder: (context, adminProvider, child) {
        // Only show FAB if admin is logged in and edit mode is active
        if (!adminProvider.isAdminLoggedIn || !adminProvider.isEditModeEnabled) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Speed dial actions
            ...widget.actions.map((action) {
              final index = widget.actions.indexOf(action);
              return AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: Container(
                        margin: EdgeInsets.only(
                          bottom: 8,
                          right: _expandAnimation.value * 8,
                        ),
                        child: FloatingActionButton(
                          onPressed: _isExpanded ? () {
                            _toggleExpanded();
                            action.onPressed();
                          } : null,
                          backgroundColor: action.backgroundColor ?? Colors.orange[300],
                          foregroundColor: Colors.white,
                          heroTag: 'speed_dial_${action.label}_$index',
                          mini: true,
                          tooltip: action.label,
                          child: action.icon,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
            const SizedBox(height: 8),
            // Main FAB
            FloatingActionButton(
              onPressed: _toggleExpanded,
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              heroTag: 'speed_dial_main',
              child: AnimatedRotation(
                turns: _isExpanded ? 0.125 : 0.0, // 45 degree rotation
                duration: const Duration(milliseconds: 300),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Configuration class for speed dial actions
class SpeedDialAction {
  final String label;
  final Widget icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const SpeedDialAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
  });
}