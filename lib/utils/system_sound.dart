import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart' as audio_session;

/// 系统提示音工具类
class SystemSound {
  static final AudioPlayer _player = AudioPlayer();
  static bool _initialized = false;
  
  /// 初始化音频会话
  static Future<void> _initAudioSession() async {
    if (_initialized) return;
    
    try {
      final session = await audio_session.AudioSession.instance;
      await session.configure(const audio_session.AudioSessionConfiguration(
        // iOS: 使用 playback 类别以支持后台播放
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.playback,
        // 允许混音
        avAudioSessionCategoryOptions: audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        // Android: 使用提示音配置
        androidAudioAttributes: audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.music,
          usage: audio_session.AndroidAudioUsage.game,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gainTransientMayDuck,
      ));
      _initialized = true;
      debugPrint('音频会话初始化成功');
    } catch (e, stackTrace) {
      debugPrint('初始化音频会话失败: $e');
      debugPrint('Stack trace: $stackTrace');
      _initialized = false;
    }
  }
  
  /// 播放等待提示音（非阻塞）
  static Future<void> playWaitingSound() async {
    try {
      await _initAudioSession();
      
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
    } catch (e, stackTrace) {
      debugPrint('播放等待提示音失败: $e');
      debugPrint('Stack trace: $stackTrace');
      // 重置播放器状态
      await _player.stop().catchError((e) => debugPrint('停止播放失败: $e'));
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
      _initialized = false;
      debugPrint('释放音频资源完成');
    } catch (e, stackTrace) {
      debugPrint('释放音频资源失败: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }
}
