import '../../data/models/language.dart';

class LanguageConfig {
  static const List<Language> supportedLanguages = [
    Language(code: "ar-SA", name: "阿拉伯语", flag: "🇸🇦"),
    Language(code: "hy-AM", name: "亚美尼亚语", flag: "🇦🇲"),
    Language(code: "az-AZ", name: "阿塞拜疆语", flag: "🇦🇿"),
    Language(code: "bs-BA", name: "波斯尼亚语", flag: "🇧🇦"),
    Language(code: "bg-BG", name: "保加利亚语", flag: "🇧🇬"),
    Language(code: "ca-ES", name: "加泰罗尼亚语", flag: "🇪🇸"),
    Language(code: "zh-CN", name: "中文", flag: "🇨🇳"),
    Language(code: "hr-HR", name: "克罗地亚语", flag: "🇭🇷"),
    Language(code: "cs-CZ", name: "捷克语", flag: "🇨🇿"),
    Language(code: "da-DK", name: "丹麦语", flag: "🇩🇰"),
    Language(code: "nl-NL", name: "荷兰语", flag: "🇳🇱"),
    Language(code: "en-US", name: "英语", flag: "🇺🇸"),
    Language(code: "et-EE", name: "爱沙尼亚语", flag: "🇪🇪"),
    Language(code: "fi-FI", name: "芬兰语", flag: "🇫🇮"),
    Language(code: "fr-FR", name: "法语", flag: "🇫🇷"),
    Language(code: "de-DE", name: "德语", flag: "🇩🇪"),
    Language(code: "el-GR", name: "希腊语", flag: "🇬🇷"),
    Language(code: "he-IL", name: "希伯来语", flag: "🇮🇱"),
    Language(code: "hi-IN", name: "印地语", flag: "🇮🇳"),
    Language(code: "hu-HU", name: "匈牙利语", flag: "🇭🇺"),
    Language(code: "is-IS", name: "冰岛语", flag: "🇮🇸"),
    Language(code: "id-ID", name: "印度尼西亚语", flag: "🇮🇩"),
    Language(code: "it-IT", name: "意大利语", flag: "🇮🇹"),
    Language(code: "ja-JP", name: "日语", flag: "🇯🇵"),
    Language(code: "kk-KZ", name: "哈萨克语", flag: "🇰🇿"),
    Language(code: "ko-KR", name: "韩语", flag: "🇰🇷"),
    Language(code: "lv-LV", name: "拉脱维亚语", flag: "🇱🇻"),
    Language(code: "lt-LT", name: "立陶宛语", flag: "🇱🇹"),
    Language(code: "mk-MK", name: "马其顿语", flag: "🇲🇰"),
    Language(code: "ms-MY", name: "马来语", flag: "🇲🇾"),
    Language(code: "mr-IN", name: "马拉地语", flag: "🇮🇳"),
    Language(code: "nb-NO", name: "挪威语", flag: "🇳🇴"),
    Language(code: "fa-IR", name: "波斯语", flag: "🇮🇷"),
    Language(code: "pl-PL", name: "波兰语", flag: "🇵🇱"),
    Language(code: "pt-BR", name: "葡萄牙语", flag: "🇧🇷"),
    Language(code: "ro-RO", name: "罗马尼亚语", flag: "🇷🇴"),
    Language(code: "ru-RU", name: "俄语", flag: "🇷🇺"),
    Language(code: "sr-RS", name: "塞尔维亚语", flag: "🇷🇸"),
    Language(code: "sk-SK", name: "斯洛伐克语", flag: "🇸🇰"),
    Language(code: "sl-SI", name: "斯洛文尼亚语", flag: "🇸🇮"),
    Language(code: "es-ES", name: "西班牙语", flag: "🇪🇸"),
    Language(code: "sw-KE", name: "斯瓦希里语", flag: "🇰🇪"),
    Language(code: "sv-SE", name: "瑞典语", flag: "🇸🇪"),
    Language(code: "ta-IN", name: "泰米尔语", flag: "🇮🇳"),
    Language(code: "th-TH", name: "泰语", flag: "🇹🇭"),
    Language(code: "tr-TR", name: "土耳其语", flag: "🇹🇷"),
    Language(code: "uk-UA", name: "乌克兰语", flag: "🇺🇦"),
    Language(code: "ur-IN", name: "乌尔都语", flag: "🇮🇳"),
    Language(code: "vi-VN", name: "越南语", flag: "🇻🇳")
  ];

  static const Language defaultSourceLanguage = Language(
    code: "zh-CN",
    name: "中文",
    flag: "🇨🇳",
  );

  static const Language defaultTargetLanguage = Language(
    code: "en-US",
    name: "英语",
    flag: "🇺🇸",
  );

  static List<Language> getAvailableTargetLanguages(String sourceLanguageCode) {
    return supportedLanguages
        .where((lang) => lang.code != sourceLanguageCode)
        .toList();
  }
}
