/// 翻译相关错误的基类
class TranslationError implements Exception {
  final String errorCode;
  final String message;

  const TranslationError(this.errorCode, this.message);

  @override
  String toString() => message;
}

/// 空转录错误：当语音无法被转录为文本时
class EmptyTranscriptionError extends TranslationError {
  EmptyTranscriptionError([String message = "No valid transcription detected"])
      : super("EMPTY_TRANSCRIPTION", message);
}

/// 语言检测错误：当无法检测音频的语言时
class LanguageDetectionError extends TranslationError {
  LanguageDetectionError([String message = "Failed to detect language"])
      : super("LANGUAGE_DETECTION_ERROR", message);
}

/// 语言不匹配错误：当检测到的语言与源语言或目标语言不匹配时
class LanguageMismatchError extends TranslationError {
  LanguageMismatchError(
    String detectedLanguage,
    String sourceLanguage,
    String targetLanguage,
  ) : super(
          "LANGUAGE_MISMATCH",
          "Detected language '$detectedLanguage' does not match "
          "source language '$sourceLanguage' or target language '$targetLanguage'. "
          "Please check if you selected the correct source and target languages.",
        );
}

/// 无效音频格式错误：当上传的音频格式不正确时
class InvalidAudioFormatError extends TranslationError {
  InvalidAudioFormatError([String message = "Invalid audio file format"])
      : super("INVALID_AUDIO_FORMAT", message);
}

/// OpenAI服务错误：当调用OpenAI服务出错时
class OpenAIServiceError extends TranslationError {
  OpenAIServiceError(Object originalError)
      : super("OPENAI_SERVICE_ERROR", originalError.toString());
}

/// Azure服务错误：当调用Azure服务出错时
class AzureServiceError extends TranslationError {
  AzureServiceError(Object originalError)
      : super("AZURE_SERVICE_ERROR", originalError.toString());
}

/// 将错误代码转换为具体的错误类型
TranslationError createTranslationError(String errorCode, String message) {
  switch (errorCode) {
    case "EMPTY_TRANSCRIPTION":
      return EmptyTranscriptionError(message);
    case "LANGUAGE_DETECTION_ERROR":
      return LanguageDetectionError(message);
    case "LANGUAGE_MISMATCH":
      return LanguageMismatchError("unknown", "unknown", "unknown");
    case "INVALID_AUDIO_FORMAT":
      return InvalidAudioFormatError(message);
    case "OPENAI_SERVICE_ERROR":
      return OpenAIServiceError(message);
    case "AZURE_SERVICE_ERROR":
      return AzureServiceError(message);
    default:
      return TranslationError(errorCode, message);
  }
}
