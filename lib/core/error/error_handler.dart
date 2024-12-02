import 'package:get/get.dart';
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
    // 可以根据错误类型选择不同的展示方式
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }
}
