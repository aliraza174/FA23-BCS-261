import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torbaaz/core/config/env_config.dart';
import 'package:torbaaz/core/config/injection_container.dart' as di;
import 'package:torbaaz/features/admin/presentation/pages/admin_setup_page.dart';
import 'package:torbaaz/features/auth/presentation/pages/login_page.dart';
import 'package:torbaaz/features/auth/presentation/pages/password_reset_page.dart';
import 'package:torbaaz/features/auth/presentation/bloc/auth_bloc.dart'
    hide AuthState;
import 'package:torbaaz/features/admin/presentation/bloc/restaurant/restaurant_bloc.dart';
import 'package:torbaaz/pages/main_screen.dart';
import 'package:torbaaz/pages/onboarding_page.dart';
import 'package:torbaaz/core/services/admin_service.dart';
import 'package:torbaaz/core/services/onboarding_service.dart';
import 'package:torbaaz/core/providers/admin_mode_provider.dart';
import 'package:torbaaz/core/providers/theme_provider.dart';
import 'package:torbaaz/core/services/admin_auth_service.dart';
import 'package:torbaaz/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

// Web-safe font initialization
void _initializeWebFonts() {
  if (kIsWeb) {
    // On web, allow runtime fetching but gracefully handle failures
    // The AppTheme will use system fonts on web as fallback
    try {
      GoogleFonts.config.allowRuntimeFetching = true;
    } catch (e) {
      debugPrint('⚠️ Warning: Could not configure Google Fonts for web: $e');
    }
  }
}

// Helper function to get web-safe fonts
TextStyle getWebSafeTextStyle({
  double? fontSize,
  FontWeight? fontWeight,
  Color? color,
  double? letterSpacing,
  double? height,
  List<Shadow>? shadows,
}) {
  if (kIsWeb) {
    // Use system fonts for web to avoid loading issues
    return TextStyle(
      fontFamily:
          '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  } else {
    // Use Google Fonts for mobile/desktop
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize web-safe fonts first
  _initializeWebFonts();

  // Load environment variables
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('âœ“ Environment variables loaded successfully');
    debugPrint(
        'â€¢ Supabase URL: ${EnvConfig.supabaseUrl.isNotEmpty ? "Configured" : "Missing"}');
    debugPrint(
        'â€¢ Supabase Key: ${EnvConfig.supabaseAnonKey.isNotEmpty ? "Configured" : "Missing"}');
  } catch (e) {
    debugPrint('âš ï¸ Warning: Could not load .env file: $e');
    debugPrint('App will try to use fallback configuration');
  }

  // Initialize Supabase with better error handling
  if (!EnvConfig.hasSupabaseConfig) {
    debugPrint('❌ Missing Supabase configuration in .env file');
    throw Exception(
        'Missing Supabase configuration. Please check your .env file.');
  }

  try {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
      // Deep link configuration for password reset on Android
      debug: kDebugMode,
    );
    debugPrint('✔ Supabase initialized successfully');
  } catch (e) {
    debugPrint('❌ Failed to initialize Supabase: $e');
    throw Exception(
        'Failed to initialize Supabase. Please check your configuration.');
  }

  // Initialize dependency injection
  await di.initDependencies();

  // Initialize admin services
  await AdminService().initialize();
  await AdminAuthService().initialize();

  // Initialize onboarding service
  await OnboardingService().initialize();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminModeProvider>(
          create: (context) => AdminModeProvider()..initialize(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (context) => ThemeProvider()..initialize(),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => di.getIt<AuthBloc>(),
        ),
        BlocProvider<RestaurantBloc>(
          create: (context) => di.getIt<RestaurantBloc>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Torbaaz',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.materialThemeMode,
            initialRoute: '/main',
            routes: {
              '/main': (context) => const OnboardingWrapper(),
              '/onboarding': (context) => OnboardingPage(
                    onComplete: () {
                      Navigator.of(context).pushReplacementNamed('/main');
                    },
                  ),
              '/login': (context) => const LoginPage(),
              '/password-reset': (context) => const PasswordResetPage(),
              '/admin-setup': (context) => const AdminSetupPage(),
            },
            onUnknownRoute: (settings) => MaterialPageRoute(
              builder: (context) => const OnboardingWrapper(),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper widget that shows onboarding for new users
class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({Key? key}) : super(key: key);

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final OnboardingService _onboardingService = OnboardingService();
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final shouldShow = await _onboardingService.shouldShowOnboarding();
    if (mounted) {
      setState(() {
        _showOnboarding = shouldShow;
        _isLoading = false;
      });
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFAF8F4),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFFF5B041),
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return OnboardingPage(
        onComplete: _onOnboardingComplete,
        onSkip: _onOnboardingComplete,
      );
    }

    return const MainScreen();
  }
}
