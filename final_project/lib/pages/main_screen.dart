import 'package:flutter/material.dart';
import '../core/widgets/admin_toggle.dart';
import '../core/widgets/admin_floating_toolbar.dart';
import '../core/providers/admin_mode_provider.dart';
import '../core/providers/theme_provider.dart';
import '../core/services/admin_service.dart';
import '../core/services/onboarding_service.dart';
import '../widgets/menu_notice_popup.dart';
import '../widgets/tip_overlay.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'menu_page.dart';
import 'food_deals_page.dart';
import 'restaurant_details_page.dart';
import 'eatables_list_page.dart';
import 'feedback_page.dart';
import 'ai_assistant_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final int _adminTapCount = 0;
  final OnboardingService _onboardingService = OnboardingService();
  bool _showTip = false;
  TipData? _currentTip;

  @override
  void initState() {
    super.initState();
    _initializeAdminSystem();
    _showMenuNoticeIfNeeded();
    _showPageTipIfNeeded();
  }

  Future<void> _initializeAdminSystem() async {
    try {
      // Initialize admin service first
      await AdminService().initialize();
      // Then initialize admin mode provider
      await AdminModeProvider().initialize();
      debugPrint('Admin system initialized successfully');
    } catch (e) {
      debugPrint('Error initializing admin system: $e');
    }
  }

  void _showMenuNoticeIfNeeded() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MenuNoticePopup.showIfNeeded(context);
    });
  }

  Future<void> _showPageTipIfNeeded() async {
    await _onboardingService.initialize();

    // Only show tips after onboarding is completed
    if (!_onboardingService.isOnboardingCompleted) return;

    // Small delay before showing tip
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      _checkAndShowTipForCurrentPage();
    }
  }

  void _checkAndShowTipForCurrentPage() {
    TipData? tip;

    switch (_selectedIndex) {
      case 0:
        tip = AppTips.menuPageTip;
        break;
      case 1:
        tip = AppTips.dealsPageTip;
        break;
      case 2:
        tip = AppTips.restaurantsPageTip;
        break;
      case 3:
        tip = AppTips.foodPageTip;
        break;
      case 5:
        tip = AppTips.aiAssistantTip;
        break;
    }

    if (tip != null && _onboardingService.shouldShowTip(tip.id)) {
      setState(() {
        _currentTip = tip;
        _showTip = true;
      });
    }
  }

  void _dismissTip() {
    if (_currentTip != null) {
      _onboardingService.markTipAsShown(_currentTip!.id);
    }
    setState(() {
      _showTip = false;
      _currentTip = null;
    });
  }

  final List<Widget> _pages = [
    const MenuPage(),
    const FoodDealsPage(),
    const RestaurantDetailsPage(),
    const EatablesListPage(),
    const FeedbackPage(),
    const AIAssistantPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Check for tips when navigating to a new page
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkAndShowTipForCurrentPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = AppTheme.backgroundColor(context);
    final cardColor = AppTheme.cardColor(context);
    final headerGradient = AppTheme.getHeaderGradient(context);
    final accentColor = AppTheme.getAccentColor(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: (_selectedIndex == 0 || _selectedIndex == 4)
          ? null
          : AppBar(
              // No app bar for menu page (index 0) and feedback page (index 4)
              backgroundColor: Colors.transparent,
              elevation: 0,
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: headerGradient,
                  ),
                ),
              ),
              actions: const [
                AdminToggle(),
              ],
            ),
      body: Stack(
        children: [
          _pages[_selectedIndex],
          const AdminFloatingToolbar(),
          // Tip overlay
          if (_showTip && _currentTip != null) _buildTipOverlay(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
              offset: const Offset(0, -4),
              blurRadius: 20,
              spreadRadius: 0,
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: BottomNavigationBar(
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.home_rounded,
                    color: _selectedIndex == 0
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_offer_rounded,
                    color: _selectedIndex == 1
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'Deals',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.restaurant_rounded,
                    color: _selectedIndex == 2
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'Restaurants',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 3
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.fastfood_rounded,
                    color: _selectedIndex == 3
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'Food',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 4
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.chat_bubble_rounded,
                    color: _selectedIndex == 4
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'Feedback',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 5
                        ? AppTheme.getAccentColor(context)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.smart_toy_rounded,
                    color: _selectedIndex == 5
                        ? Colors.white
                        : (isDarkMode
                            ? Colors.grey[400]
                            : const Color(0xFF8B8B8B)),
                    size: 24,
                  ),
                ),
                label: 'AI Chat',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor:
                isDarkMode ? Colors.white : const Color(0xFF333333),
            unselectedItemColor:
                isDarkMode ? Colors.grey[400] : const Color(0xFF8B8B8B),
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
            showUnselectedLabels: true,
            backgroundColor: cardColor,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipOverlay() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final accentColor = AppTheme.getAccentColor(context);

    return Positioned.fill(
      child: GestureDetector(
        onTap: _dismissTip,
        child: Container(
          color: Colors.black54,
          child: SafeArea(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Align(
                alignment: _currentTip!.alignment,
                child: Container(
                  margin: _currentTip!.targetMargin ??
                      const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppTheme.darkCardColor : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon with animated background
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              accentColor.withOpacity(0.2),
                              accentColor.withOpacity(0.1),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _currentTip!.icon,
                          size: 48,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        _currentTip!.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Message
                      Text(
                        _currentTip!.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color:
                              isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Got it button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _dismissTip,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Got it!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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
    );
  }
}
