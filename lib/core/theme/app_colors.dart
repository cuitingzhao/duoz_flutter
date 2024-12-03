import 'package:flutter/material.dart';

/// 应用的主题颜色
class AppColors {
  // 主要颜色
  static const Color primary = Color(0xFFFBC902);    // 主黄色
  static const Color black = Color(0xFF000000);      // 纯黑
  static const Color white = Color(0xFFFFFFFF);      // 纯白
  
  // 衍生颜色
  static const Color primaryLight = Color(0xFFFEE99B);  // 浅黄色 (主色 20% 透明度)
  static const Color blackLight = Color(0xFF333333);    // 浅黑色（用于主要文本）
  static const Color greyLight = Color(0xFFF5F5F5);     // 浅灰色（用于背景）
  
  // 文本颜色
  static const Color textPrimary = Color(0xFF000000);           // 主要文本
  static const Color textSecondary = Color(0xFF666666);    // 次要文本
  static const Color textHint = Color(0xFF999999);         // 提示文本
  static const Color textOnPrimary = Color(0xFF000000);         // 主色上的文本
  
  // 背景颜色
  static const Color background = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  
  // 功能色
  static const Color error = Color(0xFFE53935);         // 错误红
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);
}
