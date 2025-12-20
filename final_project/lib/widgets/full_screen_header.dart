import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart' show getWebSafeTextStyle;

class FullScreenHeader extends StatelessWidget {
  const FullScreenHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.backgroundImage = 'assets/images/pizza_bg.jpg',
    this.height = 300,
    this.actions,
    this.overlayColors,
  });

  final String title;
  final String subtitle;
  final String backgroundImage;
  final double height;
  final List<Widget>? actions;
  final List<Color>? overlayColors;

  @override
  Widget build(BuildContext context) {
    // Make status bar transparent for immersive experience
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 400;
    final isMobile = screenWidth < 600;

    // Responsive sizing
    final titleFontSize = isSmallScreen ? 24.0 : (isMobile ? 28.0 : 36.0);
    final subtitleFontSize = isSmallScreen ? 13.0 : (isMobile ? 14.0 : 18.0);
    final welcomeFontSize = isSmallScreen ? 12.0 : (isMobile ? 13.0 : 16.0);
    final horizontalPadding = isSmallScreen ? 12.0 : (isMobile ? 16.0 : 20.0);
    final containerPadding = isSmallScreen ? 10.0 : (isMobile ? 12.0 : 16.0);

    // Effective height based on screen size
    final effectiveHeight =
        isMobile ? (height * 0.85).clamp(200.0, 280.0) : height;

    return Container(
      height: effectiveHeight,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen background image
            Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: overlayColors ??
                          [
                            const Color(0xFFF5B041),
                            const Color(0xFFE67E22),
                          ],
                    ),
                  ),
                );
              },
            ),

            // Enhanced gradient overlay for better text readability
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x30000000), // Light at top for status bar
                    Color(0x20000000), // Very light in middle
                    Color(0x80000000), // Stronger at bottom for text
                  ],
                  stops: [0.0, 0.3, 1.0],
                ),
              ),
            ),

            // Custom color overlay if provided
            if (overlayColors != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: overlayColors!,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

            // Main content with full padding for status bar
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: isMobile ? 12 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.end, // Align content to bottom
                mainAxisSize: MainAxisSize.min, // Use minimum space needed
                children: [
                  // Top actions row (replaces app bar)
                  if (actions != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: actions!,
                    ),

                  // Flexible spacer that takes remaining space
                  const Expanded(child: SizedBox()),

                  // Welcome text - compact for mobile
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: containerPadding,
                      vertical: isMobile ? 5 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Hello, Customer!',
                      style: getWebSafeTextStyle(
                        fontSize: welcomeFontSize,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.95),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black.withOpacity(0.45),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isMobile ? 8 : 16),

                  // Main title with enhanced styling - responsive sizing
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: containerPadding + 4,
                      vertical: isMobile ? 8 : 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: getWebSafeTextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                color: Colors.black.withOpacity(0.6),
                              ),
                              Shadow(
                                offset: const Offset(1, 1),
                                blurRadius: 3,
                                color: Colors.black.withOpacity(0.45),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: isMobile ? 3 : 6),
                        Text(
                          subtitle,
                          style: getWebSafeTextStyle(
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.95),
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.45),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isMobile ? 8 : 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
