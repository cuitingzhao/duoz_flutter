import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';

typedef OnSilenceDetectedCallback = void Function();

class SoundDetector {
  // MARK: - Properties
  final OnSilenceDetectedCallback onSilenceDetected;
  final double silenceThreshold;
  
  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  Timer? _soundDetectionTimer;
  double _validSoundDuration = 0;
  double _silenceTimeAccumulator = 0;
  bool _hasDetectedSound = false;
  DateTime? _lastProcessTime;
  
  static const _silenceDuration = Duration(milliseconds: 2000);
  static const _minimumValidSoundDuration = 0.5; // 秒
  static const _checkInterval = Duration(milliseconds: 100);
  static const _maxValidSoundDuration = 30.0; // 最大录音时长（秒）
  
  // MARK: - Initialization
  SoundDetector({
    required this.onSilenceDetected,
    required this.silenceThreshold,
  });
  
  // MARK: - Public Methods
  Future<void> startMonitoring() async {
    await stopMonitoring();
    _resetState();
    
    try {
      // 检查麦克风权限
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        debugPrint('SoundDetector: 麦克风权限未授予');
        return;
      }
      
      debugPrint('SoundDetector: 开始监听，静音阈值: $silenceThreshold');
      _noiseMeter = NoiseMeter();
      _noiseSubscription = _noiseMeter?.noise.listen(
        (NoiseReading noiseReading) {
          final volume = noiseReading.maxDecibel;          
          _processVolume(volume);
        },
        onError: (Object error) {
          debugPrint('SoundDetector: 噪音监测错误 - $error');
        },
      );
      
      _soundDetectionTimer = Timer.periodic(_checkInterval, (timer) {
        // 只检查是否超过最大录音时长
        if (_validSoundDuration >= _maxValidSoundDuration) {
          debugPrint('SoundDetector: 达到最大录音时长');
          onSilenceDetected();
          _resetState();
        }
      });
      
    } catch (err) {
      debugPrint('SoundDetector: 启动噪音监测失败 - $err');
    }
  }
  
  Future<void> stopMonitoring() async {
    _soundDetectionTimer?.cancel();
    _soundDetectionTimer = null;
    await _noiseSubscription?.cancel();
    _noiseSubscription = null;
    _noiseMeter = null;
  }
  
  void _processVolume(double volume) {
    if (!_soundDetectionTimer!.isActive) return;
    
    // 计算实际的时间间隔
    final now = DateTime.now();
    final timeDiff = _lastProcessTime != null 
        ? now.difference(_lastProcessTime!).inMilliseconds / 1000.0
        : 0.0;
    _lastProcessTime = now;
    
    // 检查是否是有效声音
    final isValidSound = volume > silenceThreshold;
    debugPrint('SoundDetector: 当前音量: $volume dB，阈值: $silenceThreshold，是否有效: $isValidSound, _hasDetectedSound: $_hasDetectedSound');
    
    if (isValidSound) {
      _validSoundDuration += timeDiff;
      _silenceTimeAccumulator = 0;
      
      if (!_hasDetectedSound && _validSoundDuration >= _minimumValidSoundDuration) {
        _hasDetectedSound = true;
        debugPrint('SoundDetector: 首次检测到有效声音，持续时长: $_validSoundDuration秒');
      }
    } else if (_hasDetectedSound) {
      _silenceTimeAccumulator += timeDiff;
      debugPrint('SoundDetector: 当前静音时长: $_silenceTimeAccumulator秒');
      
      // 检查是否检测到足够长的静音
      if (_silenceTimeAccumulator >= _silenceDuration.inMilliseconds / 1000) {
        debugPrint('SoundDetector: 检测到静音，有效录音时长: $_validSoundDuration秒');
        onSilenceDetected();
        _resetState();
      }
    }
  }
  
  // MARK: - Private Methods
  void _resetState() {
    _validSoundDuration = 0;
    _silenceTimeAccumulator = 0;
    _hasDetectedSound = false;
    _lastProcessTime = null;  // 重置上次处理时间
    debugPrint('SoundDetector: 重置状态');
  }
  
  void dispose() {
    stopMonitoring();
  }
}
