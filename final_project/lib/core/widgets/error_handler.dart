import 'package:flutter/material.dart';
import '../error/failures.dart';

class ErrorHandler {
  /// Shows appropriate error message with retry functionality
  static void showErrorSnackBar(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 6),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            _getErrorIcon(failure),
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getErrorTitle(failure),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  failure.message,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: _getErrorColor(failure),
      duration: duration,
      behavior: SnackBarBehavior.floating,
      action: onRetry != null
          ? SnackBarAction(
              label: 'RETRY',
              textColor: Colors.white,
              onPressed: onRetry,
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows success message
  static void showSuccessSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.green,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Shows info message
  static void showInfoSnackBar(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.info,
            color: Colors.white,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.blue,
      duration: duration,
      behavior: SnackBarBehavior.floating,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static IconData _getErrorIcon(Failure failure) {
    if (failure is NetworkFailure) {
      return Icons.wifi_off;
    } else if (failure is AuthFailure || failure is PermissionFailure) {
      return Icons.lock;
    } else if (failure is ValidationFailure) {
      return Icons.warning;
    } else if (failure is StorageFailure) {
      return Icons.cloud_off;
    } else {
      return Icons.error;
    }
  }

  static String _getErrorTitle(Failure failure) {
    if (failure is NetworkFailure) {
      return 'Network Error';
    } else if (failure is AuthFailure) {
      return 'Authentication Error';
    } else if (failure is PermissionFailure) {
      return 'Permission Denied';
    } else if (failure is ValidationFailure) {
      return 'Validation Error';
    } else if (failure is StorageFailure) {
      return 'Storage Error';
    } else if (failure is DatabaseFailure) {
      return 'Database Error';
    } else {
      return 'Error';
    }
  }

  static Color _getErrorColor(Failure failure) {
    if (failure is NetworkFailure) {
      return Colors.orange;
    } else if (failure is AuthFailure || failure is PermissionFailure) {
      return Colors.red.shade700;
    } else if (failure is ValidationFailure) {
      return Colors.amber.shade700;
    } else if (failure is StorageFailure) {
      return Colors.purple;
    } else {
      return Colors.red;
    }
  }
}

/// Extension to make error handling more convenient
extension BuildContextErrorExtension on BuildContext {
  void showError(Failure failure, {VoidCallback? onRetry}) {
    ErrorHandler.showErrorSnackBar(this, failure, onRetry: onRetry);
  }

  void showSuccess(String message) {
    ErrorHandler.showSuccessSnackBar(this, message);
  }

  void showInfo(String message) {
    ErrorHandler.showInfoSnackBar(this, message);
  }
}