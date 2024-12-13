import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';

import 'noise_analyzer.dart';

typedef OnSilenceDetectedCallback = void Function();
typedef OnVolumeChangedCallback = void Function(double);

class SoundDetector {
  final FlutterSoundRecorder recorder;
  final Duration silenceThreshold;
  final Function() onSilenceDetected;
  final Function(double)? onVolumeChanged;
  Timer? _silenceTimer;
  StreamSubscription<RecordingDisposition>? _recorderSubscription;
  bool _isListening = false;

  // 音频处理相关变量
  static const double _minimumValidSoundDuration = 0.5; // 最小有效音频时长（秒）
  static const double _maxValidSoundDuration = 30.0;    // 最大录音时长（秒）
  double _validSoundDuration = 0;                       // 有效音频累计时长
  bool _hasDetectedSound = false;                       // 是否检测到有效声音
  DateTime? _lastProcessTime;                           // 上次处理时间

  // 音量映射参数
  static const double _minDb = 30.0;  // 最小分贝值
  static const double _maxDb = 90.0;  // 最大分贝值

  SoundDetector({
    required this.recorder,
    this.silenceThreshold = const Duration(seconds: 2),
    required this.onSilenceDetected,
    this.onVolumeChanged,
  });

  // 将分贝值映射到0-1范围
  double _mapVolumeToAmplitude(double db) {
    if (db <= _minDb) return 0.0;
    if (db >= _maxDb) return 1.0;
    return (db - _minDb) / (_maxDb - _minDb);
  }

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _resetState();

    _recorderSubscription = recorder.onProgress!.listen(
      (RecordingDisposition disposition) {
        final decibels = disposition.decibels ?? 0;
        
        // 计算并通知音量变化
        if (onVolumeChanged != null) {
          final normalizedVolume = _mapVolumeToAmplitude(decibels);
          onVolumeChanged!(normalizedVolume);
        }

        // 计算时间间隔
        final now = DateTime.now();
        final timeDiff = _lastProcessTime != null 
            ? now.difference(_lastProcessTime!).inMilliseconds / 1000.0
            : 0.0;
        _lastProcessTime = now;

        // 检查是否是有效声音
        final isValidSound = decibels >= NoiseAnalyzer.noiseThreshold;
        
        if (isValidSound) {
          _validSoundDuration += timeDiff;
          _silenceTimer?.cancel();
          _silenceTimer = null;

          if (!_hasDetectedSound && _validSoundDuration >= _minimumValidSoundDuration) {
            _hasDetectedSound = true;
            debugPrint('[SoundDetector] Valid sound detected, duration: ${_validSoundDuration.toStringAsFixed(1)}s');
          }

          // 检查是否超过最大录音时长
          if (_validSoundDuration >= _maxValidSoundDuration) {
            debugPrint('[SoundDetector] Max recording duration reached');
            onSilenceDetected();
            _resetState();
          }
        } else if (_hasDetectedSound && _silenceTimer == null) {
          // 只在检测到有效声音后且没有计时器时创建新的计时器
          _silenceTimer = Timer(const Duration(milliseconds: 1500), () {
            debugPrint('[SoundDetector] Silence detected after valid sound, valid duration: ${_validSoundDuration.toStringAsFixed(1)}s');
            onSilenceDetected();
            _resetState();
          });
        }
      },
      onError: (error) {
        debugPrint('[SoundDetector] Error monitoring decibels: $error');
      },
    );
  }

  void stopListening() {
    _isListening = false;
    _silenceTimer?.cancel();
    _recorderSubscription?.cancel();
    _resetState();
  }

  void _resetState() {
    _validSoundDuration = 0;
    _hasDetectedSound = false;
    _lastProcessTime = null;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    debugPrint('[SoundDetector] State reset');
  }

  void dispose() {
    stopListening();
  }
}
