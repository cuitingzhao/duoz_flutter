import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// 系统提示音工具类
class SystemSound {
  static final AudioPlayer _player = AudioPlayer();
  
  /// 播放等待提示音（非阻塞）
  static Future<void> playWaitingSound() async {
    try {
      // 确保音频文件存在
      final source = AssetSource('audios/loading.wav');
      debugPrint('准备播放音频: ${source.path}');
      
      // 设置循环播放
      await _player.setReleaseMode(ReleaseMode.loop);
      // 设置音量
      await _player.setVolume(0.5);  // 降低音量以避免干扰
      
      // 播放音频
      await _player.play(source);
      debugPrint('开始播放等待提示音');
    } catch (e) {
      debugPrint('播放等待提示音失败: $e');
    }
  }
  
  /// 停止播放提示音
  static Future<void> stopWaitingSound() async {
    try {
      await _player.stop();
      debugPrint('停止播放等待提示音');
    } catch (e) {
      debugPrint('停止播放等待提示音失败: $e');
    }
  }

  /// 停止播放
  static Future<void> stopSound() async {
    try {
      await _player.stop();
      debugPrint('停止播放提示音');
    } catch (e, stackTrace) {
      debugPrint('停止提示音失败: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// 释放资源
  static Future<void> dispose() async {
    try {
      await stopSound();
      await _player.dispose();
      debugPrint('释放音频资源完成');
    } catch (e, stackTrace) {
      debugPrint('释放音频资源失败: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
