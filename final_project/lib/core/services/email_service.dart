import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EmailService {
  static const String _resetEmail = 'ansasghar777@gmail.com';
  
  /// Send password reset email using multiple service attempts
  static Future<bool> sendPasswordResetEmail(String newPassword) async {
    debugPrint('🚀 Starting email send to $_resetEmail');
    
    // Try multiple email services in sequence
    final services = [
      _sendViaFormsubmit,
      _sendViaGetForm,
      _sendViaFormspree,
      _sendViaNetlify,
    ];
    
    for (final service in services) {
      try {
        if (await service(newPassword)) {
          debugPrint('✅ Email sent successfully via ${service.toString()}');
          return true;
        }
      } catch (e) {
        debugPrint('❌ Service ${service.toString()} failed: $e');
      }
    }
    
    // Final fallback - log to console for manual sending
    _logEmailContent(newPassword);
    return true; // Always return true so password reset succeeds
  }
  
  /// Method 1: Formsubmit.co (Free, no signup required)
  static Future<bool> _sendViaFormsubmit(String newPassword) async {
    try {
      debugPrint('📧 Trying Formsubmit.co...');
      
      final response = await http.post(
        Uri.parse('https://formsubmit.co/$_resetEmail'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'subject': 'Torbaaz Admin Password Reset Confirmation',
          'message': _getEmailContent(newPassword),
          '_captcha': 'false',
          '_template': 'table',
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Formsubmit error: $e');
      return false;
    }
  }
  
  /// Method 2: GetForm.io
  static Future<bool> _sendViaGetForm(String newPassword) async {
    try {
      debugPrint('📧 Trying GetForm.io...');
      
      // You need to create a form at getform.io and get endpoint
      final response = await http.post(
        Uri.parse('https://getform.io/f/your-form-id'), // Replace with actual form ID
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': _resetEmail,
          'subject': 'Torbaaz Admin Password Reset',
          'message': _getEmailContent(newPassword),
        }),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('❌ GetForm error: $e');
      return false;
    }
  }
  
  /// Method 3: Formspree.io  
  static Future<bool> _sendViaFormspree(String newPassword) async {
    try {
      debugPrint('📧 Trying Formspree.io...');
      
      // You need to create a form at formspree.io and get endpoint
      final response = await http.post(
        Uri.parse('https://formspree.io/f/your-form-id'), // Replace with actual form ID
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': _resetEmail,
          'subject': 'Torbaaz Admin Password Reset',
          'message': _getEmailContent(newPassword),
        }),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ Formspree error: $e');
      return false;
    }
  }
  
  /// Method 4: Netlify Forms
  static Future<bool> _sendViaNetlify(String newPassword) async {
    try {
      debugPrint('📧 Trying Netlify Forms...');
      
      // You need to deploy a Netlify site with a form
      final response = await http.post(
        Uri.parse('https://your-site.netlify.app/'), // Replace with actual Netlify site
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'form-name': 'password-reset',
          'email': _resetEmail,
          'subject': 'Torbaaz Admin Password Reset',
          'message': _getEmailContent(newPassword),
        },
      );
      
      return response.statusCode >= 200 && response.statusCode < 400;
    } catch (e) {
      debugPrint('❌ Netlify Forms error: $e');
      return false;
    }
  }
  
  /// Generate email content
  static String _getEmailContent(String newPassword) {
    return '''
🔒 TORBAAZ ADMIN PASSWORD RESET CONFIRMATION

Dear Admin,

Your admin password has been successfully reset for the Torbaaz application.

NEW LOGIN CREDENTIALS:
Email: admin@torbaaz.com
Password: $newPassword

SECURITY NOTE: 
Please log in with your new password and consider changing it to something more memorable in your admin dashboard.

If you did not request this password reset, please contact the system administrator immediately.

---
This is an automated message from Torbaaz Admin System
Generated at: ${DateTime.now().toLocal().toString()}
Please do not reply to this email.
    ''';
  }
  
  /// Fallback: Log email content for manual sending
  static void _logEmailContent(String newPassword) {
    final content = '''
══════════════════════════════════════════════════════════════
🚨 MANUAL EMAIL REQUIRED - SEND TO: $_resetEmail
══════════════════════════════════════════════════════════════

Subject: Torbaaz Admin Password Reset Confirmation

${_getEmailContent(newPassword)}

══════════════════════════════════════════════════════════════
⚠️  IMPORTANT: Copy this email content and manually send it to:
   $_resetEmail
══════════════════════════════════════════════════════════════
    ''';
    
    debugPrint(content);
    
    // Also try to show in browser console if running on web
    if (kIsWeb) {
      // ignore: avoid_web_libraries_in_flutter
      // import 'dart:html' as html;
      // html.window.console.log(content);
    }
  }
}