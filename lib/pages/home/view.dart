import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../core/config/language_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'controller.dart';
import 'widgets/language_picker.dart';
import 'widgets/source_language_selector.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'DuoZ',
          style: AppTextStyles.headline2,
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(
        children: [
          // 环境描述
          // Positioned(
          //   top: 0,
          //   left: 0,
          //   right: 0,
          //   child: Container(
          //     padding: EdgeInsets.all(16.w),
          //     color: AppColors.primaryLight,
          //     child: Row(
          //       children: [
          //         // Icon(
          //         //   Icons.volume_up,
          //         //   size: 24.w,
          //         //   color: AppColors.textSecondary,
          //         // ),
          //         // SizedBox(width: 8.w),
          //         Expanded(
          //           child: Obx(() => Text(
          //             '当前环境: ${controller.environmentDescription.value}',
          //             textAlign: TextAlign.center,
          //             style: AppTextStyles.environment,
          //           )),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),

          // 源语言选择器（顶部居中）
          Positioned(
            top: 30.h,
            left: 0,
            right: 0,
            child: Obx(() => SourceLanguageSelector(
              selectedLanguage: controller.sourceLanguage.value,
              availableLanguages: LanguageConfig.supportedLanguages,
              onLanguageSelected: controller.updateSourceLanguage,
            )),
          ),

          // 中央录音按钮和目标语言选择器
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 录音按钮
                SizedBox(
                  width: 0.7.sw,
                  height: 0.35.sw,
                  child: FloatingActionButton.extended(
                    onPressed: controller.startRecording,
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    icon: Icon(
                      Icons.mic,
                      size: 64.w,
                      color: AppColors.textOnPrimary,
                    ),
                    label: const SizedBox(), // 空的label以使用extended样式
                  ),
                ),
                
                SizedBox(height: 32.h),
                
                // 目标语言选择器
                SizedBox(
                  width: 0.7.sw,
                  child: Obx(() => LanguagePicker(
                    selectedLanguage: controller.targetLanguage.value,
                    availableLanguages: controller.availableTargetLanguages,
                    onLanguageSelected: controller.updateTargetLanguage,
                    label: '目标语言',
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}