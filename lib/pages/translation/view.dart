import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'controller.dart';
import 'widgets/waveform.dart';

class TranslationPage extends GetView<TranslationController> {
  const TranslationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 创建 AutoSizeGroup 确保源文本和翻译文本使用相同的字体大小
    final textGroup = AutoSizeGroup();
    
    return Container(
      color: AppColors.background,
      child: SafeArea(
        child: Obx(() {
          if (controller.hasError.value) {
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48.w,
                        color: AppColors.error,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        controller.errorMessage.value,
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '错误代码: ${controller.errorCode.value}',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => controller.startRecording(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Text(
                          '重试',
                          style: AppTextStyles.button,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 16.w,
                  bottom: 16.h,
                  child: SizedBox(
                    width: 64.w,
                    height: 64.w,
                    child: FloatingActionButton(
                      onPressed: () => Get.back(),
                      backgroundColor: AppColors.primary.withOpacity(0.8),
                      elevation: 4,
                      child: Icon(
                        Icons.close,
                        size: 32.w,
                        color: AppColors.textOnPrimary.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return Stack(
            children: [
              Column(
                children: [
                  // 上半部分：转录文本
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      alignment: Alignment.center,
                      child: Obx(() {
                        if (controller.isTranslating.value) {
                          return CupertinoActivityIndicator(
                            radius: 12.w,
                            color: AppColors.primary,
                          );
                        }
                        // 确保字号能被步进值整除
                        final maxFontSize = (48.sp / 4).floor() * 4;
                        final minFontSize = (20.sp / 4).floor() * 4;
                        return AutoSizeText(
                          controller.transcription.value,
                          group: textGroup,
                          style: TextStyle(
                            fontSize: 48.sp,
                            height: 1.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                          minFontSize: minFontSize.toDouble(),
                          maxFontSize: maxFontSize.toDouble(),
                          stepGranularity: 4,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        );
                      }),
                    ),
                  ),
                  
                  // 波形图
                  Container(
                    height: 120.h,
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Obx(() => WaveformWidget(
                      amplitude: controller.currentVolume.value,
                      color: controller.isRecording.value 
                          ? AppColors.primary
                          : AppColors.textSecondary.withOpacity(0.5),
                      isRecording: controller.isRecording.value,
                    )),
                  ),            
                              
                  // 下半部分：翻译文本
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      alignment: Alignment.center,
                      child: Obx(() {
                        if (controller.isTranslating.value) {
                          return const SizedBox.shrink();
                        }
                        // 确保字号能被步进值整除
                        final maxFontSize = (48.sp / 4).floor() * 4;
                        final minFontSize = (20.sp / 4).floor() * 4;
                        return AutoSizeText(
                          controller.translatedText.value,
                          group: textGroup,
                          style: TextStyle(
                            fontSize: 48.sp,
                            height: 1.5,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                          minFontSize: minFontSize.toDouble(),
                          maxFontSize: maxFontSize.toDouble(),
                          stepGranularity: 4,
                          maxLines: 8,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        );
                      }),
                    ),
                  ),
                ],
              ),
              // 悬浮关闭按钮
              Positioned(
                right: 16.w,
                bottom: 16.h,
                child: SizedBox(
                  width: 64.w,
                  height: 64.w,
                  child: FloatingActionButton(
                    onPressed: () => Get.back(),
                    backgroundColor: AppColors.primary.withOpacity(0.8),
                    elevation: 4,
                    child: Icon(
                      Icons.close,
                      size: 32.w,
                      color: AppColors.textOnPrimary.withOpacity(0.9),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
