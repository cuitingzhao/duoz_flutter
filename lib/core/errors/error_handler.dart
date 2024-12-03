import 'package:get/get.dart';
import 'package:flutter/material.dart'; // add this line
import 'app_error.dart';
import 'error_codes.dart';
import 'error_messages.dart';

class ErrorHandler {
  static void handleError(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppError) {
      _showError(error.code, error.message);
    } else {
      final appError = AppError(
        code: AppErrorCode.unknown,
        message: error.toString(),
        originalError: error,
        stackTrace: stackTrace,
      );
      _showError(appError.code, appError.message);
    }
  }

  static AppError createError(AppErrorCode code, [dynamic originalError]) {
    return AppError(
      code: code,
      message: ErrorMessages.getMessage(code),
      originalError: originalError,
    );
  }

  static void _showError(AppErrorCode code, String message) {
    Get.snackbar(
      '错误提示',  // title
      message,    // message
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade200,
      borderWidth: 1,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
      icon: Icon(
        Icons.error_outline,
        color: Colors.red.shade700,
      ),
      shouldIconPulse: true,
      titleText: Text(
        '错误提示',
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
      messageText: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: TextStyle(
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '错误代码: $code',
            style: TextStyle(
              color: Colors.red.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
