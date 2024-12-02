import 'error_codes.dart';

class AppError implements Exception {
  final AppErrorCode code;
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppError({
    required this.code,
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppError: [$code] $message';
}
