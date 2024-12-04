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
        avAudioSessionCategory: audio_session.AVAudioSessionCategory.ambient,
        avAudioSessionCategoryOptions: audio_session.AVAudioSessionCategoryOptions.mixWithOthers,
        androidAudioAttributes: audio_session.AndroidAudioAttributes(
          contentType: audio_session.AndroidAudioContentType.sonification,
          usage: audio_session.AndroidAudioUsage.notificationCommunicationInstant,
        ),
        androidAudioFocusGainType: audio_session.AndroidAudioFocusGainType.gain,
      ));
      _initialized = true;
    } catch (e) {
      debugPrint('初始化音频会话失败: $e');
    }
  }
  
  /// 播放等待提示音（非阻塞）
  static Future<void> playWaitingSound() async {
    try {
      await _initAudioSession();
      // 循环播放
      await _player.setReleaseMode(ReleaseMode.loop);
      // 非阻塞播放
      _player.play(AssetSource('audios/loading.wav'), volume: 1);
    } catch (e) {
      debugPrint('播放等待提示音失败: $e');
    }
  }

  /// 停止播放
  static Future<void> stopSound() async {
    try {
      await _player.stop();
    } catch (e) {
      debugPrint('停止提示音失败: $e');
    }
  }

  /// 释放资源
  static Future<void> dispose() async {
    await _player.dispose();
    _initialized = false;
  }
}
