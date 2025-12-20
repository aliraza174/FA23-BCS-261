import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'email_service.dart';
import 'simple_email_service.dart';

class AdminAuthService {
  static final AdminAuthService _instance = AdminAuthService._internal();
  factory AdminAuthService() => _instance;
  AdminAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _adminSessionKey = 'admin_session_active';
  static const String _adminEmailKey = 'admin_email';
  static const String _adminLoginTimeKey = 'admin_login_time';

  // Hardcoded admin credentials for development
  static const String _adminEmail = 'admin@torbaaz.com';
  static String _adminPassword = 'TorbaazAdmin@707';
  static const String _resetEmail = 'ansasghar777@gmail.com';

  bool _isAdminAuthenticated = false;
  String? _currentAdminEmail;
  bool _isInitialized = false;

  bool get isAuthenticated => _isAdminAuthenticated;
  String? get currentAdminEmail => _currentAdminEmail;

  /// Initialize and restore admin session if it exists
  Future<void> initialize() async {
    if (_isInitialized) return; // Prevent multiple initializations

    try {
      await _loadSavedPassword();
      await _restoreAdminSession();
      _isInitialized = true;
      debugPrint('AdminAuthService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing AdminAuthService: $e');
    }
  }

  /// Authenticate admin with credentials
  Future<bool> authenticateAdmin(String email, String password) async {
    try {
      // First check hardcoded admin credentials
      if (email.toLowerCase().trim() == _adminEmail.toLowerCase() &&
          password == _adminPassword) {
        debugPrint('✅ Admin authenticated with hardcoded credentials');
        await _setAdminSession(email);
        return true;
      }

      // Fall back to Supabase authentication for other admin users
      try {
        final response = await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (response.user != null) {
          debugPrint('✅ Admin authenticated via Supabase');
          await _setAdminSession(email);
          return true;
        }
      } catch (supabaseError) {
        debugPrint('🔸 Supabase auth failed: $supabaseError');
        // Continue to return false below
      }

      debugPrint('❌ Invalid admin credentials provided');
      return false;
    } catch (e) {
      debugPrint('Admin authentication error: $e');
      return false;
    }
  }

  /// Set admin session and persist it
  Future<void> _setAdminSession(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_adminSessionKey, true);
      await prefs.setString(_adminEmailKey, email);
      await prefs.setString(
          _adminLoginTimeKey, DateTime.now().toIso8601String());

      _isAdminAuthenticated = true;
      _currentAdminEmail = email;

      debugPrint('Admin session set for: $email');
    } catch (e) {
      debugPrint('Error setting admin session: $e');
    }
  }

  /// Restore admin session from storage
  Future<void> _restoreAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAdminActive = prefs.getBool(_adminSessionKey) ?? false;
      final adminEmail = prefs.getString(_adminEmailKey);
      final loginTimeStr = prefs.getString(_adminLoginTimeKey);

      if (isAdminActive && adminEmail != null && loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final now = DateTime.now();
        final sessionDuration = now.difference(loginTime);

        // Keep session active for 24 hours
        if (sessionDuration.inHours < 24) {
          _isAdminAuthenticated = true;
          _currentAdminEmail = adminEmail;
          debugPrint('Admin session restored for: $adminEmail');
        } else {
          // Session expired, clear it silently
          _isAdminAuthenticated = false;
          _currentAdminEmail = null;
          debugPrint('Admin session expired, cleared silently');
        }
      }
    } catch (e) {
      debugPrint('Error restoring admin session: $e');
    }
  }

  /// Clear admin session
  Future<void> clearAdminSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_adminSessionKey);
      await prefs.remove(_adminEmailKey);
      await prefs.remove(_adminLoginTimeKey);

      _isAdminAuthenticated = false;
      _currentAdminEmail = null;

      debugPrint('Admin session cleared');
    } catch (e) {
      debugPrint('Error clearing admin session: $e');
    }
  }

  /// Check if current session is valid
  Future<bool> isSessionValid() async {
    if (!_isAdminAuthenticated) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final loginTimeStr = prefs.getString(_adminLoginTimeKey);

      if (loginTimeStr != null) {
        final loginTime = DateTime.parse(loginTimeStr);
        final sessionDuration = DateTime.now().difference(loginTime);
        return sessionDuration.inHours < 24;
      }
    } catch (e) {
      debugPrint('Error checking session validity: $e');
    }

    return false;
  }

  /// Refresh session timestamp
  Future<void> refreshSession() async {
    if (_isAdminAuthenticated) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            _adminLoginTimeKey, DateTime.now().toIso8601String());
        debugPrint('Admin session refreshed');
      } catch (e) {
        debugPrint('Error refreshing session: $e');
      }
    }
  }

  /// Validate reset email
  bool validateResetEmail(String email) {
    return email.toLowerCase().trim() == _resetEmail;
  }

  /// Send password reset email using dedicated email service
  Future<bool> sendPasswordResetEmail(String newPassword) async {
    debugPrint('ðŸš€ Starting email send process for $_resetEmail');

    // Use the dedicated email service that tries multiple providers
    return await EmailService.sendPasswordResetEmail(newPassword);
  }

  /// Send verification email with code (Step 1 of new workflow)
  Future<bool> sendVerificationEmail(String verificationCode) async {
    debugPrint(
        '🚀 Sending verification email with code: $verificationCode to $_resetEmail');

    try {
      // Use the simplified, reliable email service
      final success =
          await SimpleEmailService.sendVerificationCode(verificationCode);

      if (success) {
        debugPrint('✅ Verification email sent successfully to $_resetEmail');
        return true;
      } else {
        debugPrint('❌ Failed to send verification email');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error in verification email process: $e');
      return false;
    }
  }

  /// Send password reset email using Supabase Auth (Primary method - works on Android)
  /// This sends a password reset link to the admin's email address
  Future<bool> sendSupabasePasswordResetEmail(String email) async {
    debugPrint('🚀 Sending Supabase Auth password reset email to $email');

    try {
      // Validate that this is the correct admin reset email
      if (!validateResetEmail(email)) {
        debugPrint('❌ Invalid admin email for password reset');
        return false;
      }

      // Use Supabase Auth's built-in password reset
      // This will send an email with a magic link to reset the password
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo:
            'io.supabase.torbaaz://reset-callback', // Deep link for mobile
      );

      debugPrint('✅ Supabase password reset email sent successfully to $email');
      return true;
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Auth error: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error sending Supabase password reset email: $e');
      return false;
    }
  }

  /// Update password after user clicks the reset link in email
  /// This is called when the user is redirected back to the app with a valid session
  Future<bool> updatePasswordFromResetLink(String newPassword) async {
    debugPrint('🔐 Updating password from reset link...');

    try {
      // Check if we have a valid session from the reset link
      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint(
            '❌ No valid session found. User needs to click the reset link in email.');
        return false;
      }

      // Update the password using Supabase Auth
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        debugPrint('✅ Password updated successfully via Supabase Auth');

        // Also update our local admin password for hardcoded login
        _adminPassword = newPassword;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('admin_password', newPassword);

        return true;
      }

      debugPrint('❌ Failed to update password - no user returned');
      return false;
    } on AuthException catch (e) {
      debugPrint('❌ Supabase Auth error updating password: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('❌ Error updating password: $e');
      return false;
    }
  }

  /// Check if we have a valid password reset session (user clicked the email link)
  bool hasValidResetSession() {
    final session = _supabase.auth.currentSession;
    return session != null;
  }

  /// Get reset email address (for display purposes)
  String get resetEmail => _resetEmail;

  /// Simple email service using a direct SMTP-like approach
  Future<bool> _sendViaSimpleEmailService(String code) async {
    debugPrint('ðŸ“§ Trying simple email service...');

    try {
      // Use a webhook service like ntfy.sh or similar for immediate delivery
      final response = await http.post(
        Uri.parse('https://ntfy.sh/torbaaz-admin'),
        headers: {
          'Content-Type': 'text/plain',
          'Title': 'Torbaaz Admin Verification Code',
          'Priority': '5',
          'Tags': 'key,lock',
        },
        body:
            'Your Torbaaz admin verification code is: $code\n\nEnter this code to reset your password.\n\nThis message was sent to ansasghar777@gmail.com',
      );

      if (response.statusCode == 200) {
        debugPrint('âœ… Simple email service: Notification sent');
        // Also try a direct email approach
        return await _sendDirectEmail(code);
      }

      return false;
    } catch (e) {
      debugPrint('âŒ Simple email service error: $e');
      return false;
    }
  }

  /// Direct email sending approach
  Future<bool> _sendDirectEmail(String code) async {
    try {
      final emailData = {
        'to': _resetEmail,
        'from': 'admin@torbaaz.com',
        'subject': 'Torbaaz Admin Verification Code: $code',
        'text': '''
TORBAAZ ADMIN EMAIL VERIFICATION

Your verification code is: $code

Please enter this 6-digit code in the password reset form to continue.

This code will expire in 10 minutes for security purposes.

If you did not request this password reset, please ignore this email.

---
This is an automated message from Torbaaz Admin System
Do not reply to this email.
        ''',
      };

      // Try multiple direct email services
      final services = [
        'https://api.web3forms.com/submit',
        'https://api.staticforms.xyz/submit',
        'https://formcarry.com/s/torbaaz',
      ];

      for (final serviceUrl in services) {
        try {
          final response = await http.post(
            Uri.parse(serviceUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode({
              ...emailData,
              'access_key': 'torbaaz-admin-key',
              '_subject': 'Torbaaz Admin Verification Code',
              'message': emailData['text'],
              '_next': 'https://torbaaz.com/success',
              '_captcha': 'false',
            }),
          );

          if (response.statusCode >= 200 && response.statusCode < 300) {
            debugPrint('âœ… Direct email sent via $serviceUrl');
            return true;
          }
        } catch (e) {
          debugPrint('âŒ Direct email failed via $serviceUrl: $e');
        }
      }

      return false;
    } catch (e) {
      debugPrint('âŒ Direct email error: $e');
      return false;
    }
  }

  /// Try sending verification email via Formsubmit.co
  Future<bool> _sendVerificationViaFormsubmit(String code) async {
    debugPrint('ðŸ“§ Trying Formsubmit.co for verification email...');

    try {
      final response = await http.post(
        Uri.parse('https://formsubmit.co/$_resetEmail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'subject': 'Torbaaz Admin Verification Code',
          'message':
              'Your Torbaaz admin verification code is: $code\n\nPlease enter this code to reset your password.\n\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore.',
          '_captcha': 'false',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('âœ… Formsubmit: Email sent successfully');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('âŒ Formsubmit error: $e');
      return false;
    }
  }

  /// Webhook-based email service
  Future<bool> _sendVerificationViaWebHook(String code) async {
    debugPrint('ðŸ“§ Trying webhook email service...');

    try {
      // Use a simple webhook service
      final response = await http.post(
        Uri.parse(
            'https://webhook.site/unique-id'), // Replace with actual webhook
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'to': _resetEmail,
          'subject': 'Torbaaz Verification Code',
          'code': code,
          'message': 'Your verification code is: $code',
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('âœ… Webhook: Email request sent');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('âŒ Webhook error: $e');
      return false;
    }
  }

  /// Try sending verification email via generic HTTP service
  Future<bool> _sendVerificationViaHTTP(String code, String content) async {
    debugPrint('ðŸ“§ Trying HTTP email service...');

    try {
      // Try a simple email API service
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send-form'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'service_id': 'gmail',
          'template_id': 'verification',
          'user_id': 'public_key',
          'template_params': {
            'to_email': _resetEmail,
            'subject': 'Torbaaz Admin Email Verification',
            'message': 'Your verification code is: $code\n\n$content',
            'verification_code': code,
          },
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('âœ… HTTP service: Verification email sent successfully');
        return true;
      } else {
        debugPrint('âŒ HTTP service failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('âŒ HTTP service error: $e');
      return false;
    }
  }

  /// Try sending verification email via Supabase Edge Function
  Future<bool> _sendVerificationViaSupabase(String code, String content) async {
    debugPrint('ðŸ“§ Trying Supabase edge function...');

    try {
      final response =
          await _supabase.functions.invoke('send-verification-email', body: {
        'to_email': _resetEmail,
        'verification_code': code,
        'message': content,
      });

      if (response.data != null && response.data['success'] == true) {
        debugPrint('âœ… Supabase: Verification email sent successfully');
        return true;
      } else {
        debugPrint('âŒ Supabase failed: ${response.data}');
        return false;
      }
    } catch (e) {
      debugPrint('âŒ Supabase error: $e');
      return false;
    }
  }

  /// Change password after email verification (Step 3 of new workflow)
  Future<bool> changePasswordAfterVerification(String newPassword) async {
    debugPrint('ðŸ”’ Changing password after verification');

    try {
      // Update the admin password
      _adminPassword = newPassword;

      // Store the new password in SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_password', newPassword);

      debugPrint('âœ… Admin password changed successfully');
      return true;
    } catch (e) {
      debugPrint('âŒ Error changing password: $e');
      return false;
    }
  }

  /// Reset admin password
  Future<bool> resetAdminPassword(
      String email, String newPassword, String confirmPassword) async {
    try {
      // Validate email
      if (!validateResetEmail(email)) {
        debugPrint('Invalid reset email provided');
        return false;
      }

      // Validate password match
      if (newPassword != confirmPassword) {
        debugPrint('Passwords do not match');
        return false;
      }

      // Validate password strength
      if (newPassword.length < 8) {
        debugPrint('Password too short');
        return false;
      }

      // Send verification email
      final emailSent = await sendPasswordResetEmail(newPassword);
      if (!emailSent) {
        debugPrint('Failed to send verification email');
        return false;
      }

      // Update the admin password
      _adminPassword = newPassword;

      // Store the new password in SharedPreferences for persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('admin_password', newPassword);

      debugPrint('Admin password reset successfully');
      return true;
    } catch (e) {
      debugPrint('Error resetting admin password: $e');
      return false;
    }
  }

  /// Load saved password from SharedPreferences
  Future<void> _loadSavedPassword() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPassword = prefs.getString('admin_password');
      if (savedPassword != null) {
        _adminPassword = savedPassword;
      }
    } catch (e) {
      debugPrint('Error loading saved password: $e');
    }
  }
}
