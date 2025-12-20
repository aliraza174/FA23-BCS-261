import 'package:flutter/material.dart';
import '../core/services/onboarding_service.dart';

/// Onboarding page data model
class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final String? imagePath;

  const OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.imagePath,
  });
}

/// Interactive onboarding walkthrough for new users
class OnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback? onSkip;

  const OnboardingPage({
    Key? key,
    required this.onComplete,
    this.onSkip,
  }) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final OnboardingService _onboardingService = OnboardingService();
  int _currentPage = 0;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Onboarding slides data
  final List<OnboardingItem> _items = const [
    OnboardingItem(
      title: 'Welcome to Torbaaz! 🍕',
      description:
          'Discover the best restaurants and delicious food options in your area. Browse menus, find deals, and satisfy your cravings!',
      icon: Icons.restaurant_menu,
      backgroundColor: Color(0xFFF5B041),
      iconColor: Colors.white,
    ),
    OnboardingItem(
      title: 'Explore Restaurant Menus 📋',
      description:
          'Browse through detailed menus from local restaurants. View prices, descriptions, and mouth-watering food images.',
      icon: Icons.menu_book_rounded,
      backgroundColor: Color(0xFFE67E22),
      iconColor: Colors.white,
    ),
    OnboardingItem(
      title: 'Find Amazing Deals 🎉',
      description:
          'Never miss out on special offers! Discover exclusive deals and discounts from your favorite restaurants.',
      icon: Icons.local_offer_rounded,
      backgroundColor: Color(0xFF9B59B6),
      iconColor: Colors.white,
    ),
    OnboardingItem(
      title: 'Discover Restaurants 🏪',
      description:
          'Explore local restaurants, view their details, ratings, and contact information. Find the perfect place to dine!',
      icon: Icons.storefront_rounded,
      backgroundColor: Color(0xFF3498DB),
      iconColor: Colors.white,
    ),
    OnboardingItem(
      title: 'Browse Food Items 🍔',
      description:
          'Search and filter through various food items. Find exactly what you\'re craving from multiple restaurants.',
      icon: Icons.fastfood_rounded,
      backgroundColor: Color(0xFF27AE60),
      iconColor: Colors.white,
    ),
    OnboardingItem(
      title: 'AI-Powered Assistant 🤖',
      description:
          'Have questions? Our AI assistant is here to help! Get personalized recommendations and answers about restaurants and food.',
      icon: Icons.smart_toy_rounded,
      backgroundColor: Color(0xFF2B1B4D),
      iconColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );
    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    // Reset animations for new page
    _scaleController.reset();
    _scaleController.forward();
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await _onboardingService.completeOnboarding();
    widget.onComplete();
  }

  void _skipOnboarding() {
    if (widget.onSkip != null) {
      widget.onSkip!();
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _items[_currentPage].backgroundColor,
                  _items[_currentPage].backgroundColor.withOpacity(0.7),
                  Colors.black.withOpacity(0.3),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page indicator text
                      Text(
                        '${_currentPage + 1}/${_items.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      // Skip button
                      TextButton(
                        onPressed: _skipOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _items.length,
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      return _buildPage(_items[index], index == _currentPage);
                    },
                  ),
                ),

                // Page indicators
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => _buildPageIndicator(index),
                    ),
                  ),
                ),

                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white54,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      // Next/Get Started button
                      Expanded(
                        flex: _currentPage == 0 ? 1 : 1,
                        child: ElevatedButton(
                          onPressed: _nextPage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor:
                                _items[_currentPage].backgroundColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 8,
                            shadowColor: Colors.black38,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _currentPage == _items.length - 1
                                    ? 'Get Started!'
                                    : 'Next',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _currentPage == _items.length - 1
                                    ? Icons.check_circle_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                    height: MediaQuery.of(context).padding.bottom > 0 ? 8 : 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingItem item, bool isActive) {
    // Get screen dimensions for responsive sizing
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenHeight < 700;

    final iconSize = isSmallScreen ? 100.0 : 160.0;
    final iconInnerSize = isSmallScreen ? 50.0 : 80.0;
    final titleFontSize = isSmallScreen ? 24.0 : 32.0;
    final descFontSize = isSmallScreen ? 14.0 : 17.0;
    final verticalSpacing = isSmallScreen ? 24.0 : 50.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth < 400 ? 20 : 30,
          vertical: 20,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: isSmallScreen ? 20 : 40),
            // Animated icon
            ScaleTransition(
              scale: isActive
                  ? _scaleAnimation
                  : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  size: iconInnerSize,
                  color: item.iconColor,
                ),
              ),
            ),
            SizedBox(height: verticalSpacing),

            // Title
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                item.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.2,
                  shadows: const [
                    Shadow(
                      offset: Offset(0, 2),
                      blurRadius: 10,
                      color: Colors.black38,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 16 : 24),

            // Description
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                item.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: descFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 20 : 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 10,
      width: isActive ? 30 : 10,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(5),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
    );
  }
}
