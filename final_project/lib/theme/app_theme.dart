import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Light theme colors
  static const Color lightBackground = Color(0xFFFAF8F4);
  static const Color lightSurface = Colors.white;
  static const Color lightCardColor = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightHeaderGradientStart = Color(0xFFF5B041);
  static const Color lightHeaderGradientEnd = Color(0xFFE67E22);

  // Dark theme colors - coral orange and dark palette (matching mockup)
  static const Color darkBackground = Color(0xFF0D1117); // Very dark blue-black
  static const Color darkSurface = Color(0xFF161B22); // Slightly lighter dark
  static const Color darkCardColor = Color(0xFF21262D); // Card background
  static const Color darkTextPrimary = Color(0xFFFFFFFF); // White text
  static const Color darkTextSecondary = Color(0xFF8B949E); // Muted gray text
  static const Color darkHeaderGradientStart =
      Color(0xFFFF6B35); // Coral orange start
  static const Color darkHeaderGradientEnd =
      Color(0xFFE55100); // Coral orange end
  static const Color darkAccent = Color(0xFFFF6B35); // Coral orange accent
  static const Color darkDivider = Color(0xFF30363D); // Dark divider
  static const Color darkSearchBar = Color(0xFF21262D); // Search bar background

  // Common colors
  static const Color primaryOrange = Color(0xFFF5B041);
  static const Color secondaryOrange = Color(0xFFE67E22);

  // Web-safe font family
  static const String _webSafeFontFamily =
      '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif';

  /// Get a text style that works on both web and mobile
  static TextStyle _getTextStyle({
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    Color? color,
  }) {
    if (kIsWeb) {
      return TextStyle(
        fontFamily: _webSafeFontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
      );
    }
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Get background color based on brightness
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkBackground
        : lightBackground;
  }

  /// Get surface color based on brightness
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : lightSurface;
  }

  /// Get card color based on brightness
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : lightCardColor;
  }

  /// Get primary text color based on brightness
  static Color getTextPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  /// Get secondary text color based on brightness
  static Color getTextSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextSecondary
        : lightTextSecondary;
  }

  /// Check if dark mode is active
  static bool isDarkMode(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  // Shorter method aliases for convenience
  static Color backgroundColor(BuildContext context) =>
      getBackgroundColor(context);
  static Color cardColor(BuildContext context) => getCardColor(context);
  static Color textColor(BuildContext context) => getTextPrimaryColor(context);
  static Color textSecondary(BuildContext context) =>
      getTextSecondaryColor(context);

  /// Get header gradient colors based on brightness
  static List<Color> getHeaderGradient(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? [darkHeaderGradientStart, darkHeaderGradientEnd]
        : [lightHeaderGradientStart, lightHeaderGradientEnd];
  }

  /// Get accent color based on brightness
  static Color getAccentColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : primaryOrange;
  }

  /// Get button selected color based on brightness
  static Color getButtonSelectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkAccent
        : primaryOrange;
  }

  /// Get button unselected color based on brightness
  static Color getButtonUnselectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkCardColor
        : Colors.grey.shade300;
  }

  /// Get button text color based on selection and brightness
  static Color getButtonTextColor(BuildContext context, bool isSelected) {
    if (isSelected) return Colors.white;
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  /// Get divider color
  static Color getDividerColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : Colors.grey.shade300;
  }

  /// Get search bar background color
  static Color getSearchBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSearchBar
        : Colors.white;
  }

  /// Get icon color based on brightness
  static Color getIconColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkTextPrimary
        : lightTextPrimary;
  }

  /// Get filter chip unselected background color
  static Color getChipUnselectedColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkSurface
        : Colors.grey.shade200;
  }

  /// Get filter chip border color
  static Color getChipBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? darkDivider
        : Colors.grey.shade400;
  }

  /// Get text field input text style - black text in both light and dark mode
  static TextStyle getTextFieldTextStyle(BuildContext context) {
    return const TextStyle(
      color: Colors.black87,
      fontSize: 16,
    );
  }

  static InputDecoration getTextFieldDecoration({
    required String labelText,
    IconData? prefixIcon,
    String? hintText,
    BuildContext? context,
  }) {
    final isDark =
        context != null && Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: isDark ? Colors.grey.shade600 : null)
          : null,
      filled: true,
      fillColor: Colors.white, // Always white background for input fields
      labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade700),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orange, width: 2),
      ),
    );
  }

  static const TextStyle textFieldStyle = TextStyle(
    color: Colors.black,
    fontSize: 16,
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2B1B4D),
      Color(0xFF1A0B2E),
    ],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4169E1),
      Color(0xFF00BFFF),
    ],
  );

  static final buttonStyle = ButtonStyle(
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    ),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ),
    elevation: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) return 8;
      if (states.contains(WidgetState.pressed)) return 4;
      return 6;
    }),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.hovered)) {
        return const Color(0xFF5179F1);
      }
      return const Color(0xFF4169E1);
    }),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    overlayColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        return Colors.white.withOpacity(0.1);
      }
      return null;
    }),
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white.withOpacity(0.1),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: Colors.white.withOpacity(0.2),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  );

  static const textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      letterSpacing: -1,
    ),
    displayMedium: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    ),
    bodyMedium: TextStyle(
      fontSize: 16,
      color: Colors.white70,
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      canvasColor: lightSurface,
      cardColor: lightCardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: primaryOrange,
        unselectedItemColor: lightTextSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        labelStyle: TextStyle(color: Colors.grey.shade700),
        counterStyle: const TextStyle(color: lightTextSecondary),
        errorStyle: const TextStyle(color: Colors.red),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryOrange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightCardColor,
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: const TextStyle(color: lightSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: _getTextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: lightTextPrimary),
        displayMedium: _getTextStyle(
            fontSize: 28, fontWeight: FontWeight.w600, color: lightTextPrimary),
        displaySmall: _getTextStyle(
            fontSize: 24, fontWeight: FontWeight.w500, color: lightTextPrimary),
        headlineMedium: _getTextStyle(
            fontSize: 20, fontWeight: FontWeight.w500, color: lightTextPrimary),
        headlineSmall: _getTextStyle(
            fontSize: 18, fontWeight: FontWeight.w400, color: lightTextPrimary),
        titleLarge: _getTextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: lightTextPrimary),
        bodyLarge: _getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: lightTextPrimary),
        bodyMedium: _getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: lightTextSecondary),
        titleMedium: _getTextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: lightTextPrimary),
        titleSmall: _getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: lightTextSecondary),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.light,
        surface: lightSurface,
        onSurface: lightTextPrimary,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.orange,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      canvasColor: darkSurface,
      cardColor: darkCardColor,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkAccent,
        unselectedItemColor: darkTextSecondary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: TextStyle(color: darkTextSecondary.withOpacity(0.7)),
        labelStyle: const TextStyle(color: darkTextSecondary),
        counterStyle: const TextStyle(color: darkTextSecondary),
        errorStyle: const TextStyle(color: Colors.redAccent),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: primaryOrange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade700),
          borderRadius: BorderRadius.circular(12),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: darkCardColor,
        elevation: 4,
        shadowColor: Colors.black45,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCardColor,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: _getTextStyle(
            fontSize: 32, fontWeight: FontWeight.bold, color: darkTextPrimary),
        displayMedium: _getTextStyle(
            fontSize: 28, fontWeight: FontWeight.w600, color: darkTextPrimary),
        displaySmall: _getTextStyle(
            fontSize: 24, fontWeight: FontWeight.w500, color: darkTextPrimary),
        headlineMedium: _getTextStyle(
            fontSize: 20, fontWeight: FontWeight.w500, color: darkTextPrimary),
        headlineSmall: _getTextStyle(
            fontSize: 18, fontWeight: FontWeight.w400, color: darkTextPrimary),
        titleLarge: _getTextStyle(
            fontSize: 16, fontWeight: FontWeight.w400, color: darkTextPrimary),
        bodyLarge: _getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
            color: darkTextPrimary),
        bodyMedium: _getTextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: darkTextSecondary),
        titleMedium: _getTextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: darkTextPrimary),
        titleSmall: _getTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: darkTextSecondary),
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryOrange,
        brightness: Brightness.dark,
        surface: darkSurface,
        onSurface: darkTextPrimary,
      ),
      useMaterial3: true,
    );
  }
}
