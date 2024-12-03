import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../data/models/language.dart';
import '../../utils/audio_utils.dart';
import '../../data/services/translation_service.dart';
import '../../utils/noise_analyzer.dart';
import 'package:record/record.dart';
import '../../utils/sound_detector.dart';

class TranslationController extends GetxController {
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _audioRecorder;
  late final AudioUtils audioUtils;
  StreamController<List<int>>? audioStreamController;
  final _translationService = TranslationService();
  
  // 音频状态
  final isRecording = false.obs;
  final currentVolume = 0.0.obs;
  
  // 翻译状态
  final isTranslating = false.obs;
  final transcription = ''.obs;
  final translatedText = ''.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  
  // 源语言和目标语言
  late final Language sourceLanguage;
  late final Language targetLanguage;  
  
  // 声音检测
  late final SoundDetector _soundDetector;


  
  @override
  void onInit() {
    super.onInit();
    _soundDetector = SoundDetector(
      onSilenceDetected: () {
        debugPrint('TranslationController: 检测到静音');
        if (isRecording.value) {
          stopRecordingAndTranslate();
        }
      },
      onVolumeUpdate: (volume) {
        // 计算与阈值的差值
        final volumeDiff = volume - NoiseAnalyzer.noiseThreshold;
        
        if (volumeDiff <= 0) {
          // 低于阈值时，保持一个很小的恒定值
          currentVolume.value = 0.5;  // 5% 的基础振幅
        } else {
          // 高于阈值时，根据超出阈值的部分计算振幅
          // 将超出部分映射到 5-100 的范围（保持最小 5% 的振幅）
          final maxExcess = 80.0;  // 超出阈值 25dB 时达到最大振幅
          final normalizedVolume = ((volumeDiff) / maxExcess * 15 + 5.0).clamp(5.0, 100.0);
          currentVolume.value = normalizedVolume;
        }
      },
      silenceThreshold: NoiseAnalyzer.noiseThreshold,
    );
    
    // 监听录音状态变化
    ever(isRecording, (bool recording) {
      debugPrint('TranslationController: 录音状态变化 - $recording');
      if (recording) {
        _soundDetector.startMonitoring();
      } else {
        _soundDetector.stopMonitoring();
      }
    });
    
    try {
      // 初始化音频相关组件
      _audioPlayer = AudioPlayer();
      // 监听播放器状态
      _audioPlayer.playerStateStream.listen((state) {
        debugPrint('播放器状态变化: ${state.processingState}');
        if (state.processingState == ProcessingState.completed) {
          debugPrint('音频播放完成，开始新的录音');
          startRecording();
        }
      });
      
      _audioRecorder = AudioRecorder();
      audioUtils = AudioUtils(_audioPlayer, _audioRecorder);
      
      // 从路由参数中获取语言设置
      final args = Get.arguments as Map<String, dynamic>;
      sourceLanguage = args['sourceLanguage'] as Language;
      targetLanguage = args['targetLanguage'] as Language;
      debugPrint('TranslationController: 语言设置 - 源语言: ${sourceLanguage.code}, 目标语言: ${targetLanguage.code}');  
      // 自动开始录音
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //debugPrint('TranslationController: 准备自动开始录音');
        await startRecording();
      });
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 初始化错误 - $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  void onClose() {
    debugPrint('TranslationController: 关闭');
    _soundDetector.dispose();    
      if (audioStreamController != null) {
        audioStreamController!.close();
      }
    audioUtils.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.onClose();
  }
  
  // 开始录音
  Future<void> startRecording() async {
    debugPrint('TranslationController: 开始录音');
    try {
      await audioUtils.startRecording();
      isRecording.value = true;
      debugPrint('TranslationController: 录音已开始');
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 开始录音失败 - $e');
      debugPrint('Stack trace: $stackTrace');
      isRecording.value = false;
      rethrow;
    }
  }

  // 停止录音并开始翻译
  Future<void> stopRecordingAndTranslate() async {
    debugPrint('TranslationController: 停止录音并开始翻译');
    try {
      final audioPath = await audioUtils.stopRecording();
      debugPrint('TranslationController: 录音已停止，文件路径: $audioPath');
      isRecording.value = false;
      
      // 停止音量监听
      currentVolume.value = 0.0;
      debugPrint('TranslationController: 音量监听已停止');
      
      if (audioPath != null) {
        await translateRecordedAudio(audioPath);
      } else {
        debugPrint('TranslationController: 没有录音文件生成');
      }
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 停止录音或翻译过程出错 - $e');
      debugPrint('Stack trace: $stackTrace');
      isRecording.value = false;
      isTranslating.value = false;
      hasError.value = true;
      errorMessage.value = e.toString();
      rethrow;
    }
  }

  // 音频翻译
  Future<void> translateRecordedAudio(String audioPath) async {
    debugPrint('TranslationController: 开始翻译录音');
    isTranslating.value = true;
    bool audioStarted = false;
    
    try {      
      // 创建新的 StreamController 用于本次音频播放
      audioStreamController?.close();  
      audioStreamController = StreamController<List<int>>();
      debugPrint('TranslationController: 创建新的音频流控制器');
      
      await for (final response in _translationService.translateAudio(
        audioPath,
        sourceLanguage.code,
        targetLanguage.code,
      )) {
        debugPrint('收到翻译响应，类型: ${response.type}');
        isTranslating.value = false;
        
        switch (response.type) {
          case TranslationResponseType.transcription:
            final text = response.data as String;
            debugPrint('设置转录文本: $text');
            transcription.value = text;
            break;
            
          case TranslationResponseType.translation:
            final text = response.data as String;
            debugPrint('设置翻译文本: $text');
            translatedText.value = text;
            break;
            
          case TranslationResponseType.audioChunk:
            final audioData = response.data as List<int>;
            debugPrint('收到音频数据块，大小: ${audioData.length}字节');
            
            if (!audioStarted) {
              debugPrint('首次收到音频，开始播放流');
              audioStarted = true;
              final controller = audioStreamController;
              if (controller != null) {
                unawaited(audioUtils.playback(controller.stream));
              }
            }
            
            debugPrint('添加音频数据到流');
            audioStreamController?.add(audioData);
            break;
            
          case TranslationResponseType.audioEnd:
            debugPrint('收到音频结束标记，等待音频播放完成');
            await audioStreamController?.close();
            await audioUtils.markStreamEnd();  // 标记音频流结束
                      
            debugPrint('音频播放完成');
            break;
            
          case TranslationResponseType.error:
            final errorMsg = response.data as String;
            debugPrint('翻译错误: $errorMsg');
            hasError.value = true;
            errorMessage.value = errorMsg;
            break;
            
          case TranslationResponseType.audioStart:
            debugPrint('收到音频开始标记，等待音频数据');
            break;
        }
      }                  
      debugPrint('翻译过程结束');
    } catch (e) {
      debugPrint('翻译过程出错: $e');
      rethrow;
    } finally {
      isTranslating.value = false;
    }
  }  

}