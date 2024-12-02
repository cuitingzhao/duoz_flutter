import 'package:get/get.dart';
import '../../core/config/language_config.dart';
import '../../core/routes/app_pages.dart';
import '../../data/models/language.dart';

class HomeController extends GetxController {
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
  }

  // 更新源语言
  void updateSourceLanguage(Language language) {
    if (language.code == targetLanguage.value.code) {
      // 如果新的源语言与当前目标语言相同，则将目标语言更改为第一个可用的其他语言
      final newTargetLanguages = LanguageConfig.getAvailableTargetLanguages(language.code);
      targetLanguage.value = newTargetLanguages.first;
    }
    sourceLanguage.value = language;
  }

  // 更新目标语言
  void updateTargetLanguage(Language language) {
    if (language.code != sourceLanguage.value.code) {
      targetLanguage.value = language;
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
