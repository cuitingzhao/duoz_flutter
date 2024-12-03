enum AppErrorCode {
  // General errors
  unknown,
  networkError,
  serverError,
  
  // Audio related errors
  audioPermissionDenied,
  audioInitializationFailed,
  audioRecordingFailed,
  audioPlaybackFailed,
  
  // Recording specific errors
  recordingTooShort,
  recordingTooLong,
  noiseThresholdNotMet,
  
  // Translation related errors
  translationFailed,
  unsupportedLanguage,
  languageMismatch,  // 检测到的语言与选择的源语言或目标语言不匹配
  
  // Device related errors
  microphoneNotAvailable,
  speakerNotAvailable,
  
  // Noise analysis errors
  noiseAnalysisFailed,
  
  // File operation errors
  fileSaveFailed,
  fileReadFailed,
  
  // Permission errors
  permissionDenied,
}
