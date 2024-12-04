import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audio_session/audio_session.dart';
import '../../core/config/language_config.dart';
import '../../core/routes/app_pages.dart';
import '../../data/models/language.dart';

class HomeController extends GetxController {
  // SharedPreferences keys
  static const String _sourceLanguageKey = 'source_language_code';
  static const String _targetLanguageKey = 'target_language_code';
  
  // 环境噪音描述
  final environmentDescription = ''.obs;
  
  // 语言选择
  final sourceLanguage = LanguageConfig.defaultSourceLanguage.obs;
  final targetLanguage = LanguageConfig.defaultTargetLanguage.obs;
  
  // 可用的目标语言列表
  List<Language> get availableTargetLanguages => 
      LanguageConfig.getAvailableTargetLanguages(sourceLanguage.value.code);
  
  @override
  void onInit() {
    super.onInit();
    // 从路由参数中获取环境描述
    final description = Get.arguments?['environmentDescription'] as String?;
    environmentDescription.value = description ?? '未知环境';
    
    // 加载保存的语言选择
    _loadSavedLanguages();
    
    // 初始化音频会话
    _initAudioSession();
  }

  // 加载保存的语言选择
  Future<void> _loadSavedLanguages() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载源语言
    final savedSourceCode = prefs.getString(_sourceLanguageKey);
    if (savedSourceCode != null) {
      final savedLanguage = LanguageConfig.supportedLanguages
          .firstWhere((lang) => lang.code == savedSourceCode,
                     orElse: () => LanguageConfig.defaultSourceLanguage);
      sourceLanguage.value = savedLanguage;
    }
    
    // 加载目标语言
    final savedTargetCode = prefs.getString(_targetLanguageKey);
    if (savedTargetCode != null) {
      final savedLanguage = LanguageConfig.supportedLanguages
          .firstWhere((lang) => lang.code == savedTargetCode,
                     orElse: () => LanguageConfig.defaultTargetLanguage);
      if (savedLanguage.code != sourceLanguage.value.code) {
        targetLanguage.value = savedLanguage;
      }
    }
  }

  // 初始化音频会话
  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.allowBluetooth |
            AVAudioSessionCategoryOptions.defaultToSpeaker ,
        avAudioSessionMode: AVAudioSessionMode.voicePrompt,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.notifyOthersOnDeactivation,
        androidAudioAttributes: const AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      ));
      debugPrint('音频会话初始化成功');
    } catch (e) {
      debugPrint('音频会话初始化失败: $e');
    }
  }

  // 保存语言选择
  Future<void> _saveLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceLanguageKey, sourceLanguage.value.code);
    await prefs.setString(_targetLanguageKey, targetLanguage.value.code);
  }

  // 更新源语言
  void updateSourceLanguage(Language language) {
    if (language.code == targetLanguage.value.code) {
      // 如果新的源语言与当前目标语言相同，则将目标语言更改为第一个可用的其他语言
      final newTargetLanguages = LanguageConfig.getAvailableTargetLanguages(language.code);
      targetLanguage.value = newTargetLanguages.first;
    }
    sourceLanguage.value = language;
    _saveLanguagePreference();
  }

  // 更新目标语言
  void updateTargetLanguage(Language language) {
    if (language.code != sourceLanguage.value.code) {
      targetLanguage.value = language;
      _saveLanguagePreference();
    }
  }

  // 开始录音并导航到翻译页面
  void startRecording() {
    Get.toNamed(
      Routes.TRANSLATION,
      arguments: {
        'sourceLanguage': sourceLanguage.value,
        'targetLanguage': targetLanguage.value,
      },
    );
  }
}
