import 'dart:async';
import 'package:flutter/material.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../core/errors/error_codes.dart';
import '../core/errors/error_handler.dart';

class NoiseAnalyzer {
  static const Duration ANALYSIS_DURATION = Duration(seconds: 3);
  
  // 噪音级别阈值（分贝）
  static const double QUIET_THRESHOLD = 50.0;     // 安静环境
  static const double MODERATE_THRESHOLD = 65.0;  // 正常对话
  static const double NOISY_THRESHOLD = 80.0;     // 嘈杂环境
  
  // 当前环境噪音阈值
  static double noiseThreshold = MODERATE_THRESHOLD;
  
  // 音量流控制器
  static final _volumeController = StreamController<double>.broadcast();
  
  // 音量流
  static Stream<double> get volumeStream => _volumeController.stream;
  
  // 获取环境描述
  static String getEnvironmentDescription() {
    if (noiseThreshold <= QUIET_THRESHOLD) {
      return '安静环境';
    } else if (noiseThreshold <= MODERATE_THRESHOLD) {
      return '正常环境';
    } else {
      return '嘈杂环境';
    }
  }

  // 分析环境噪音并设置阈值
  static Future<void> analyzeNoise() async {
    NoiseMeter? noiseMeter;
    StreamSubscription<NoiseReading>? subscription;
    final completer = Completer<void>();
    Timer? analysisTimer;    
    
    try {
      // 检查麦克风权限
      final permissionStatus = await _checkPermission();
      if (!permissionStatus.isGranted) {
        if (permissionStatus.isPermanentlyDenied) {
          // 显示对话框，提示用户去设置中开启权限
          final bool? openSettings = await Get.dialog<bool>(
            AlertDialog(
              title: const Text('需要麦克风权限'),
              content: const Text('请在设置中开启麦克风权限，以便检测环境噪音。'),
              actions: [
                TextButton(
                  onPressed: () => Get.back(result: false),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Get.back(result: true),
                  child: const Text('去设置'),
                ),
              ],
            ),
            barrierDismissible: false,
          );
          
          if (openSettings == true) {
            await openAppSettings();
          }
        }
        throw ErrorHandler.createError(AppErrorCode.audioPermissionDenied);
      }

      debugPrint('开始噪音分析...');
      List<double> noiseReadings = [];

      // 初始化 NoiseMeter
      try {
        noiseMeter = NoiseMeter();
      } catch (e) {
        debugPrint('NoiseMeter 初始化失败: $e');
        throw ErrorHandler.createError(AppErrorCode.noiseAnalysisFailed, '初始化失败');
      }
      
      // 开始收集噪音数据
      try {
        subscription = noiseMeter.noise.listen(
          (noiseReading) {
            if (noiseReading != null && noiseReading.maxDecibel > 0) {  // 过滤无效值
              debugPrint('收到噪音数据: ${noiseReading.maxDecibel} dB');
              noiseReadings.add(noiseReading.maxDecibel);
              _volumeController.add(noiseReading.maxDecibel / 100); // 将分贝值转换为0-1之间的值
            }
          },
          onError: (e) {
            debugPrint('噪音监听错误: $e');
            completer.completeError(e);
          },
          cancelOnError: true,
        );
      } catch (e) {
        debugPrint('设置噪音监听失败: $e');
        throw ErrorHandler.createError(AppErrorCode.noiseAnalysisFailed, '监听失败');
      }

      // 设置定时器，在指定时间后停止收集数据
      analysisTimer = Timer(ANALYSIS_DURATION, () {
        _cleanupResources(subscription, null);
        
        if (noiseReadings.isEmpty) {
          debugPrint('没有收集到有效的噪音数据');
          if (!completer.isCompleted) {
            completer.completeError(ErrorHandler.createError(
              AppErrorCode.noiseAnalysisFailed,
              'No valid noise readings collected',
            ));
          }
        } else {
          try {
            // 计算平均噪音水平
            final averageNoise = noiseReadings.reduce((a, b) => a + b) / noiseReadings.length;
            debugPrint('平均噪音水平: $averageNoise dB');
            _setNoiseThreshold(averageNoise);
            if (!completer.isCompleted) {
              completer.complete();
            }
          } catch (e) {
            debugPrint('计算噪音水平失败: $e');
            if (!completer.isCompleted) {
              completer.completeError(ErrorHandler.createError(
                AppErrorCode.noiseAnalysisFailed,
                '数据处理失败',
              ));
            }
          }
        }
      });

      return completer.future;
    } catch (e, stackTrace) {
      debugPrint('噪音分析异常: $e\n$stackTrace');
      _cleanupResources(subscription, analysisTimer);
      rethrow;
    }
  }

  // 清理资源
  static void _cleanupResources(StreamSubscription<NoiseReading>? subscription, Timer? timer) {
    try {
      subscription?.cancel();
    } catch (e) {
      debugPrint('取消订阅失败: $e');
    }
    
    try {
      timer?.cancel();
    } catch (e) {
      debugPrint('取消定时器失败: $e');
    }
  }

  // 根据环境噪音设置阈值
  static void _setNoiseThreshold(double averageNoise) {
    debugPrint('设置噪音阈值，平均噪音: $averageNoise dB');
    if (averageNoise <= QUIET_THRESHOLD) {
      noiseThreshold = QUIET_THRESHOLD;
    } else if (averageNoise <= MODERATE_THRESHOLD) {
      noiseThreshold = MODERATE_THRESHOLD;
    } else {
      noiseThreshold = NOISY_THRESHOLD;
    }
    debugPrint('最终设置的阈值: $noiseThreshold dB');
  }

  // 检查麦克风权限
  static Future<PermissionStatus> _checkPermission() async {
    final status = await Permission.microphone.status;
    debugPrint('当前麦克风权限状态: $status');
    
    if (status.isGranted) {
      return status;
    }
    
    debugPrint('请求麦克风权限...');
    final result = await Permission.microphone.request();
    debugPrint('权限请求结果: $result');
    return result;
  }
}