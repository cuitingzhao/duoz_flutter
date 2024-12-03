import '../../data/models/language.dart';

class LanguageConfig {
  static const List<Language> supportedLanguages = [
    Language(code: "ar-SA", name: "العربية", flag: "🇸🇦"),
    Language(code: "hy-AM", name: "Հայերեն", flag: "🇦🇲"),
    Language(code: "az-AZ", name: "Azərbaycan", flag: "🇦🇿"),
    Language(code: "bs-BA", name: "Bosanski", flag: "🇧🇦"),
    Language(code: "bg-BG", name: "Български", flag: "🇧🇬"),
    Language(code: "ca-ES", name: "Català", flag: "🇪🇸"),
    Language(code: "zh-CN", name: "中文", flag: "🇨🇳"),
    Language(code: "hr-HR", name: "Hrvatski", flag: "🇭🇷"),
    Language(code: "cs-CZ", name: "Čeština", flag: "🇨🇿"),
    Language(code: "da-DK", name: "Dansk", flag: "🇩🇰"),
    Language(code: "nl-NL", name: "Nederlands", flag: "🇳🇱"),
    Language(code: "en-US", name: "English", flag: "🇺🇸"),
    Language(code: "et-EE", name: "Eesti", flag: "🇪🇪"),
    Language(code: "fi-FI", name: "Suomi", flag: "🇫🇮"),
    Language(code: "fr-FR", name: "Français", flag: "🇫🇷"),
    Language(code: "de-DE", name: "Deutsch", flag: "🇩🇪"),
    Language(code: "el-GR", name: "Ελληνικά", flag: "🇬🇷"),
    Language(code: "he-IL", name: "עברית", flag: "🇮🇱"),
    Language(code: "hi-IN", name: "हिन्दी", flag: "🇮🇳"),
    Language(code: "hu-HU", name: "Magyar", flag: "🇭🇺"),
    Language(code: "is-IS", name: "Íslenska", flag: "🇮🇸"),
    Language(code: "id-ID", name: "Bahasa Indonesia", flag: "🇮🇩"),
    Language(code: "it-IT", name: "Italiano", flag: "🇮🇹"),
    Language(code: "ja-JP", name: "日本語", flag: "🇯🇵"),
    Language(code: "kk-KZ", name: "Қазақ", flag: "🇰🇿"),
    Language(code: "ko-KR", name: "한국어", flag: "🇰🇷"),
    Language(code: "lv-LV", name: "Latviešu", flag: "🇱🇻"),
    Language(code: "lt-LT", name: "Lietuvių", flag: "🇱🇹"),
    Language(code: "mk-MK", name: "Македонски", flag: "🇲🇰"),
    Language(code: "ms-MY", name: "Bahasa Melayu", flag: "🇲🇾"),
    Language(code: "mr-IN", name: "मराठी", flag: "🇮🇳"),
    Language(code: "nb-NO", name: "Norsk Bokmål", flag: "🇳🇴"),
    Language(code: "fa-IR", name: "فارسی", flag: "🇮🇷"),
    Language(code: "pl-PL", name: "Polski", flag: "🇵🇱"),
    Language(code: "pt-BR", name: "Português", flag: "🇧🇷"),
    Language(code: "ro-RO", name: "Română", flag: "🇷🇴"),
    Language(code: "ru-RU", name: "Русский", flag: "🇷🇺"),
    Language(code: "sr-RS", name: "Српски", flag: "🇷🇸"),
    Language(code: "sk-SK", name: "Slovenčina", flag: "🇸🇰"),
    Language(code: "sl-SI", name: "Slovenščina", flag: "🇸🇮"),
    Language(code: "es-ES", name: "Español", flag: "🇪🇸"),
    Language(code: "sw-KE", name: "Kiswahili", flag: "🇰🇪"),
    Language(code: "sv-SE", name: "Svenska", flag: "🇸🇪"),
    Language(code: "ta-IN", name: "தமிழ்", flag: "🇮🇳"),
    Language(code: "th-TH", name: "ไทย", flag: "🇹🇭"),
    Language(code: "tr-TR", name: "Türkçe", flag: "🇹🇷"),
    Language(code: "uk-UA", name: "Українська", flag: "🇺🇦"),
    Language(code: "ur-IN", name: "اردو", flag: "🇮🇳"),
    Language(code: "vi-VN", name: "Tiếng Việt", flag: "🇻🇳")
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
