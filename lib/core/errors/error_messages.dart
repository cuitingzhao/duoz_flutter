import 'error_codes.dart';

class ErrorMessages {
  static const Map<AppErrorCode, String> messages = {
    AppErrorCode.unknown: '发生未知错误',
    AppErrorCode.networkError: '网络连接错误',
    AppErrorCode.serverError: '服务器错误',
    
    // Audio related errors
    AppErrorCode.audioPermissionDenied: '未获得录音权限',
    AppErrorCode.audioInitializationFailed: '音频初始化失败',
    AppErrorCode.audioRecordingFailed: '录音失败',
    AppErrorCode.audioPlaybackFailed: '音频播放失败',
    
    // Recording specific errors
    AppErrorCode.recordingTooShort: '录音时间太短',
    AppErrorCode.recordingTooLong: '录音时间超出限制',
    AppErrorCode.noiseThresholdNotMet: '未检测到有效声音',
    
    // Translation related errors
    AppErrorCode.translationFailed: '翻译失败',
    AppErrorCode.unsupportedLanguage: '不支持的语言',
    
    // Device related errors
    AppErrorCode.microphoneNotAvailable: '麦克风不可用',
    AppErrorCode.speakerNotAvailable: '扬声器不可用',
    
    // Noise analysis errors
    AppErrorCode.noiseAnalysisFailed: '噪音分析失败',
    
    // File operation errors
    AppErrorCode.fileSaveFailed: '文件保存失败',
    AppErrorCode.fileReadFailed: '文件读取失败',
    
    // Permission errors
    AppErrorCode.permissionDenied: '权限被拒绝',
  };

  static String getMessage(AppErrorCode code) {
    return messages[code] ?? messages[AppErrorCode.unknown]!;
  }
}
