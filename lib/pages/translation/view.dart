import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'controller.dart';
import 'widgets/waveform.dart';

class TranslationPage extends GetView<TranslationController> {
  const TranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Get.back(),
            color: Colors.black87,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  '错误代码: ${controller.errorCode.value}',
                  style: TextStyle(color: Colors.grey),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => controller.startRecording(),
                  child: Text('重试'),
                ),
              ],
            ),
          );
        }
        return SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // 上半部分：转录文本
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: Obx(() {
                        if (controller.isTranslating.value) {
                          return const CupertinoActivityIndicator(
                            radius: 12,
                          );
                        }
                        return Text(
                          controller.transcription.value,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }),
                    ),
                  ),
                  
                  // 波形图
                  Container(
                    height: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Obx(() => WaveformWidget(
                      amplitude: controller.currentVolume.value,
                      color: controller.isRecording.value 
                          ? Colors.blue 
                          : Colors.grey.withOpacity(0.5),
                      isRecording: controller.isRecording.value,
                    )),
                  ),            
                              
                  // 下半部分：翻译文本
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      alignment: Alignment.center,
                      child: Obx(() {
                        if (controller.isTranslating.value) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          controller.translatedText.value,
                          style: const TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }),
    );
  }
}
