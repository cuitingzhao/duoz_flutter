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
      body: SafeArea(
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

                // 录音控制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Obx(() => FloatingActionButton(
                    onPressed: controller.isRecording.value
                        ? controller.stopRecordingAndTranslate
                        : null,
                    backgroundColor: controller.isRecording.value
                        ? Colors.red
                        : Colors.grey,
                    child: const Icon(Icons.stop),
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
            
            // 错误提示
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 16.0,
              child: Obx(() {
                if (!controller.hasError.value) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => controller.hasError.value = false,
                        color: Colors.red.shade700,
                        iconSize: 20.0,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
