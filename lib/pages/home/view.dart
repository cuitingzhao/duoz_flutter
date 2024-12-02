import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/config/language_config.dart';
import 'controller.dart';
import 'widgets/language_picker.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DuoZ Flutter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // 环境描述
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.volume_up),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => Text(
                    '当前环境: ${controller.environmentDescription.value}',
                    style: Theme.of(context).textTheme.titleMedium,
                  )),
                ),
              ],
            ),
          ),
          
          // 语言选择和录音按钮
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 源语言选择器
                  Obx(() => LanguagePicker(
                    selectedLanguage: controller.sourceLanguage.value,
                    availableLanguages: LanguageConfig.supportedLanguages,
                    onLanguageSelected: controller.updateSourceLanguage,
                    label: '源语言',
                  )),
                  
                  const SizedBox(height: 20),
                  
                  // 交换语言图标
                  Icon(
                    Icons.arrow_downward,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // 目标语言选择器
                  Obx(() => LanguagePicker(
                    selectedLanguage: controller.targetLanguage.value,
                    availableLanguages: controller.availableTargetLanguages,
                    onLanguageSelected: controller.updateTargetLanguage,
                    label: '目标语言',
                  )),
                  
                  const SizedBox(height: 40),
                  
                  // 录音按钮
                  FloatingActionButton.extended(
                    onPressed: controller.startRecording,
                    icon: const Icon(Icons.mic),
                    label: const Text('开始录音'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}