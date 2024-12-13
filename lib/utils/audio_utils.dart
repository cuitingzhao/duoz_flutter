import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_tts/flutter_tts.dart';

/// 音频工具类，专注于音频录制和TTS功能
class AudioUtils {
  final FlutterSoundRecorder _soundRecorder;
  final FlutterTts _tts;
  String? _recordingPath;

  AudioUtils(this._soundRecorder) : _tts = FlutterTts() {
    _initTts();
  }

  /// 初始化录音机
  Future<void> _initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    
    await _soundRecorder.openRecorder();
    await _soundRecorder.setSubscriptionDuration(const Duration(milliseconds: 10));
  }

  /// 初始化 TTS
  Future<void> _initTts() async {
    try {
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5); // 设置语速，0.5 是较慢的语速
      
      _tts.setCompletionHandler(() {
        debugPrint('[AudioUtils] TTS completed');
      });

      _tts.setErrorHandler((msg) {
        debugPrint('[AudioUtils] TTS error: $msg');
      });
    } catch (e) {
      debugPrint('[AudioUtils] Error initializing TTS: $e');
      rethrow;
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    try {
      await _initRecorder();
      
      // 创建临时文件路径
      final dir = await getTemporaryDirectory();
      _recordingPath = path.join(dir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      
      // 配置录音参数并开始录音
      await _soundRecorder.startRecorder(
        toFile: _recordingPath,
        codec: Codec.pcm16WAV,
        sampleRate: 44100,
        numChannels: 1,
      );
    } catch (e) {
      debugPrint('[AudioUtils] Error starting recording: $e');
      rethrow;
    }
  }

  /// 停止录音
  Future<String?> stopRecording() async {
    try {      
      _recordingPath = await _soundRecorder.stopRecorder();
      return _recordingPath;
    } catch (e) {
      debugPrint('[AudioUtils] Error stopping recording: $e');
      rethrow;
    }
  }

  /// 使用 TTS 播放文本
  Future<void> speak(String text, String language) async {
    try {
      await _tts.setLanguage(language);
      await _tts.speak(text);
    } catch (e) {
      debugPrint('[AudioUtils] Error in TTS speak: $e');
      rethrow;
    }
  }

  /// 停止 TTS
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
      debugPrint('[AudioUtils] TTS stopped');
    } catch (e) {
      debugPrint('[AudioUtils] Error stopping TTS: $e');
      rethrow;
    }
  }

  /// 清理临时录音文件
  Future<void> cleanupRecordingFile() async {
    try {
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
          debugPrint('[AudioUtils] Deleted temporary recording file: $_recordingPath');
        }
      }
    } catch (e) {
      debugPrint('[AudioUtils] Error deleting recording file: $e');
    }
    _recordingPath = null;
  }

  /// 释放资源
  Future<void> dispose() async {
    await stopSpeaking();
    await _tts.stop();
    await _soundRecorder.closeRecorder();
    await cleanupRecordingFile();
  }
}