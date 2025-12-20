import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding state and user preferences for tutorials
class OnboardingService {
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _tipShownPrefixKey = 'tip_shown_';
  static const String _firstLaunchKey = 'first_launch_date';
  static const String _tipsEnabledKey = 'tips_enabled';
  static const String _appLaunchCountKey = 'app_launch_count';

  bool _isOnboardingCompleted = false;
  bool _isInitialized = false;
  bool _tipsEnabled = true;
  int _appLaunchCount = 0;
  final Set<String> _shownTips = {};

  bool get isOnboardingCompleted => _isOnboardingCompleted;
  bool get isInitialized => _isInitialized;
  bool get tipsEnabled =>
      _tipsEnabled && _appLaunchCount <= 1; // Only show tips on first launch

  /// Initialize the onboarding service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _isOnboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;
      _tipsEnabled = prefs.getBool(_tipsEnabledKey) ?? true;
      _appLaunchCount = prefs.getInt(_appLaunchCountKey) ?? 0;

      // Increment launch count
      _appLaunchCount++;
      await prefs.setInt(_appLaunchCountKey, _appLaunchCount);

      // Load shown tips
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_tipShownPrefixKey)) {
          final tipId = key.substring(_tipShownPrefixKey.length);
          if (prefs.getBool(key) == true) {
            _shownTips.add(tipId);
          }
        }
      }

      // Record first launch if not already recorded
      if (!prefs.containsKey(_firstLaunchKey)) {
        await prefs.setString(
            _firstLaunchKey, DateTime.now().toIso8601String());
      }

      _isInitialized = true;
      debugPrint(
          '✅ OnboardingService initialized. Completed: $_isOnboardingCompleted, Launch count: $_appLaunchCount');
    } catch (e) {
      debugPrint('❌ Error initializing OnboardingService: $e');
    }
  }

  /// Check if onboarding should be shown
  Future<bool> shouldShowOnboarding() async {
    await initialize();
    return !_isOnboardingCompleted;
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, true);
      _isOnboardingCompleted = true;
      debugPrint('✅ Onboarding marked as completed');
    } catch (e) {
      debugPrint('❌ Error completing onboarding: $e');
    }
  }

  /// Reset onboarding (for testing or if user wants to see it again)
  Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingCompletedKey, false);
      _isOnboardingCompleted = false;

      // Also reset all tips
      final keys = prefs.getKeys().toList();
      for (final key in keys) {
        if (key.startsWith(_tipShownPrefixKey)) {
          await prefs.remove(key);
        }
      }
      _shownTips.clear();

      debugPrint('✅ Onboarding reset');
    } catch (e) {
      debugPrint('❌ Error resetting onboarding: $e');
    }
  }

  /// Check if a specific tip has been shown
  bool isTipShown(String tipId) {
    return _shownTips.contains(tipId);
  }

  /// Mark a tip as shown
  Future<void> markTipAsShown(String tipId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_tipShownPrefixKey$tipId', true);
      _shownTips.add(tipId);
      debugPrint('✅ Tip "$tipId" marked as shown');
    } catch (e) {
      debugPrint('❌ Error marking tip as shown: $e');
    }
  }

  /// Check if a tip should be shown (not shown before and onboarding completed, first launch only)
  bool shouldShowTip(String tipId) {
    // Only show tips on the first app launch after onboarding
    if (!_isOnboardingCompleted) return false;

    // Disable tips after first launch to avoid being annoying
    if (_appLaunchCount > 1) return false;

    // Don't show if tips are disabled
    if (!_tipsEnabled) return false;

    return !_shownTips.contains(tipId);
  }

  /// Disable all tips
  Future<void> disableTips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tipsEnabledKey, false);
      _tipsEnabled = false;
      debugPrint('✅ Tips disabled');
    } catch (e) {
      debugPrint('❌ Error disabling tips: $e');
    }
  }

  /// Enable tips
  Future<void> enableTips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_tipsEnabledKey, true);
      _tipsEnabled = true;
      debugPrint('✅ Tips enabled');
    } catch (e) {
      debugPrint('❌ Error enabling tips: $e');
    }
  }

  /// Get days since first launch
  Future<int> getDaysSinceFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final firstLaunchStr = prefs.getString(_firstLaunchKey);
      if (firstLaunchStr != null) {
        final firstLaunch = DateTime.parse(firstLaunchStr);
        return DateTime.now().difference(firstLaunch).inDays;
      }
    } catch (e) {
      debugPrint('Error getting days since first launch: $e');
    }
    return 0;
  }
}
