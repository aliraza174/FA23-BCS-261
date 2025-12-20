import 'package:flutter/material.dart';
import '../core/services/onboarding_service.dart';

/// Tip data model
class TipData {
  final String id;
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Alignment alignment;
  final EdgeInsets? targetMargin;

  const TipData({
    required this.id,
    required this.title,
    required this.message,
    required this.icon,
    this.backgroundColor,
    this.alignment = Alignment.center,
    this.targetMargin,
  });
}

/// A widget that displays contextual tip overlays
class TipOverlay extends StatefulWidget {
  final Widget child;
  final TipData tip;
  final bool showOnce;
  final Duration delay;
  final VoidCallback? onDismiss;

  const TipOverlay({
    Key? key,
    required this.child,
    required this.tip,
    this.showOnce = true,
    this.delay = const Duration(milliseconds: 500),
    this.onDismiss,
  }) : super(key: key);

  @override
  State<TipOverlay> createState() => _TipOverlayState();
}

class _TipOverlayState extends State<TipOverlay>
    with SingleTickerProviderStateMixin {
  final OnboardingService _onboardingService = OnboardingService();
  bool _showTip = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _checkAndShowTip();
  }

  Future<void> _checkAndShowTip() async {
    await _onboardingService.initialize();

    if (widget.showOnce && !_onboardingService.shouldShowTip(widget.tip.id)) {
      return;
    }

    await Future.delayed(widget.delay);

    if (mounted) {
      setState(() {
        _showTip = true;
      });
      _animationController.forward();
    }
  }

  void _dismissTip() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showTip = false;
        });
        if (widget.showOnce) {
          _onboardingService.markTipAsShown(widget.tip.id);
        }
        widget.onDismiss?.call();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showTip) _buildTipOverlay(),
      ],
    );
  }

  Widget _buildTipOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismissTip,
        child: Container(
          color: Colors.black54,
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Align(
                  alignment: widget.tip.alignment,
                  child: Container(
                    margin: widget.tip.targetMargin ??
                        const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: widget.tip.backgroundColor ?? Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5B041).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.tip.icon,
                            size: 40,
                            color: const Color(0xFFF5B041),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Title
                        Text(
                          widget.tip.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Message
                        Text(
                          widget.tip.message,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Got it button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _dismissTip,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF5B041),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Got it!',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pre-defined tips for different app sections
class AppTips {
  static const TipData menuPageTip = TipData(
    id: 'menu_page_tip',
    title: '🍕 Browse Menus',
    message:
        'Swipe through restaurant menus to explore delicious food options. Tap on any item to see more details!',
    icon: Icons.swipe_rounded,
    alignment: Alignment.center,
  );

  static const TipData dealsPageTip = TipData(
    id: 'deals_page_tip',
    title: '🎉 Hot Deals',
    message:
        'Find amazing discounts and special offers here. Tap the heart icon to save your favorite deals!',
    icon: Icons.local_offer_rounded,
    alignment: Alignment.center,
  );

  static const TipData restaurantsPageTip = TipData(
    id: 'restaurants_page_tip',
    title: '🏪 Local Restaurants',
    message:
        'Discover restaurants near you. Tap on a restaurant card to view their full menu and contact details.',
    icon: Icons.storefront_rounded,
    alignment: Alignment.center,
  );

  static const TipData foodPageTip = TipData(
    id: 'food_page_tip',
    title: '🔍 Search Food',
    message:
        'Use the search bar to find specific dishes. Filter by category or mark favorites for quick access!',
    icon: Icons.search_rounded,
    alignment: Alignment.center,
  );

  static const TipData aiAssistantTip = TipData(
    id: 'ai_assistant_tip',
    title: '🤖 AI Helper',
    message:
        'Ask me anything about restaurants, food recommendations, or deals. I\'m here to help you find the perfect meal!',
    icon: Icons.smart_toy_rounded,
    alignment: Alignment.center,
  );

  static const TipData adminToggleTip = TipData(
    id: 'admin_toggle_tip',
    title: '👤 User Mode',
    message:
        'This shows your current mode. Admins can switch to Admin Mode to manage restaurant data.',
    icon: Icons.admin_panel_settings_rounded,
    alignment: Alignment.topRight,
    targetMargin: EdgeInsets.only(top: 80, right: 16, left: 100),
  );
}

/// A widget to show tips based on page navigation
class TipController extends InheritedWidget {
  final OnboardingService onboardingService;
  final void Function(TipData tip) showTip;

  const TipController({
    Key? key,
    required this.onboardingService,
    required this.showTip,
    required Widget child,
  }) : super(key: key, child: child);

  static TipController? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TipController>();
  }

  @override
  bool updateShouldNotify(TipController oldWidget) => false;
}
