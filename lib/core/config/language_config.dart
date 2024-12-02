import '../../data/models/language.dart';

class LanguageConfig {
  static const List<Language> supportedLanguages = [
    Language(code: "zh-CN", name: "中文", flag: "🇨🇳"),
    Language(code: "en-US", name: "English", flag: "🇺🇸"),
    Language(code: "ja-JP", name: "日本語", flag: "🇯🇵"),
  ];

  static const Language defaultSourceLanguage = Language(
    code: "zh-CN",
    name: "中文",
    flag: "🇨🇳",
  );

  static const Language defaultTargetLanguage = Language(
    code: "en-US",
    name: "English",
    flag: "🇺🇸",
  );

  static List<Language> getAvailableTargetLanguages(String sourceLanguageCode) {
    return supportedLanguages
        .where((lang) => lang.code != sourceLanguageCode)
        .toList();
  }
}
