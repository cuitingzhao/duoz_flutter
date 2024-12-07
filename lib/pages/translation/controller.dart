import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:logger/logger.dart';
import '../../data/models/language.dart';
import '../../utils/audio_utils.dart';
import '../../data/services/translation_service.dart';
import '../../utils/sound_detector.dart';
import 'package:duoz_flutter/core/errors/app_error.dart';
import 'package:duoz_flutter/core/errors/error_codes.dart';
import 'package:duoz_flutter/core/errors/error_handler.dart';
import '../../utils/system_sound.dart';

class TranslationController extends GetxController {
  late final just_audio.AudioPlayer _audioPlayer;
  late final FlutterSoundRecorder _audioRecorder;
  late final AudioUtils audioUtils;
  StreamController<List<int>>? audioStreamController;
  final _translationService = TranslationService();
  final isExit = false.obs;
  
  // 音频状态
  final isRecording = false.obs;
  final currentVolume = 0.0.obs;
  
  // 翻译状态
  final isTranslating = false.obs;
  final transcription = ''.obs;
  final translatedText = ''.obs;
  final hasError = false.obs;
  final errorMessage = ''.obs;
  final errorCode = ''.obs;
  
  // 源语言和目标语言
  late final Language sourceLanguage;
  late final Language targetLanguage;  
  
  // 声音检测
  late final SoundDetector _soundDetector;

  // 提示音控制
  final audioStarted = false.obs;

  // 音频播放状态
  final isAudioPlaybackStarted = false.obs;
  
  @override
  void onInit() async {
    super.onInit();
    
    try {
      _audioPlayer = just_audio.AudioPlayer();
      _audioRecorder = FlutterSoundRecorder(logLevel: Level.error);
      await _audioRecorder.openRecorder();
      await _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 100));
      
      audioUtils = AudioUtils(_audioPlayer, _audioRecorder);
      
      _soundDetector = SoundDetector(
        recorder: _audioRecorder,
        silenceThreshold: const Duration(seconds: 2),
        onSilenceDetected: () {          
          if (isRecording.value) {
            // debugPrint('[TranslationController] Silence detected, stopping recording');
            stopRecordingAndTranslate();
          }
        },
      );
      
      // 监听播放器状态
      _audioPlayer.playerStateStream.listen((state) {
         // debugPrint('播放器状态变化: ${state.processingState}');
        if (state.processingState == just_audio.ProcessingState.completed) {
          // debugPrint('音频播放完成，开始新的录音');
          startRecording();
        }
      });
      
      // 从路由参数中获取语言设置
      final args = Get.arguments as Map<String, dynamic>;
      sourceLanguage = args['sourceLanguage'] as Language;
      targetLanguage = args['targetLanguage'] as Language;
      // debugPrint('TranslationController: 语言设置 - 源语言: ${sourceLanguage.code}, 目标语言: ${targetLanguage.code}');  
      
      // 自动开始录音
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // debugPrint('TranslationController: 准备自动开始录音');
        await startRecording();
      });
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 初始化错误 - $e');
      debugPrint('Stack trace: $stackTrace');
      final error = e is AppError ? e : ErrorHandler.createError(AppErrorCode.audioInitializationFailed, e);
      ErrorHandler.handleError(error, stackTrace);
    }
  }

  @override
  void onClose() {
    isExit.value = true;    
    debugPrint('TranslationController: 关闭');
    _soundDetector.dispose();    
      if (audioStreamController != null) {
        audioStreamController!.close();
      }
    SystemSound.stopSound();    
    audioUtils.dispose();
    _audioPlayer.dispose();
    _audioRecorder.closeRecorder();
    
    super.onClose();
  }
  
  // 开始录音
  Future<void> startRecording() async {    
    // debugPrint('TranslationController: 开始录音');
    try {            
      await audioUtils.startRecording();
      isRecording.value = true;
      hasError.value = false;
      errorMessage.value = '';
      errorCode.value = '';
      await _soundDetector.startListening();
      // debugPrint('TranslationController: 录音已开始');
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 开始录音失败 - $e');
      debugPrint('Stack trace: $stackTrace');      
      isRecording.value = false;
      final error = e is AppError ? e : ErrorHandler.createError(AppErrorCode.audioRecordingFailed, e);
      ErrorHandler.handleError(error, stackTrace);
      rethrow;
    }
  }

  // 停止录音并开始翻译
  Future<void> stopRecordingAndTranslate() async {
    // debugPrint('TranslationController: 停止录音并开始翻译');
    try {
      _soundDetector.stopListening();
      final audioPath = await audioUtils.stopRecording();      
      isRecording.value = false;      
      // debugPrint('TranslationController: 录音已停止，文件路径: $audioPath');            
      // 停止音量监听
      currentVolume.value = 0.0;
      // debugPrint('TranslationController: 音量监听已停止');
      
      if (audioPath != null) {
        await translateRecordedAudio(audioPath);
      } else {
        throw ErrorHandler.createError(AppErrorCode.audioRecordingFailed, '没有录音文件生成');
      }
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 停止录音或翻译过程出错 - $e');
      debugPrint('Stack trace: $stackTrace');
      isRecording.value = false;
      isTranslating.value = false;      
      final error = e is AppError ? e : ErrorHandler.createError(AppErrorCode.unknown, e);
      ErrorHandler.handleError(error, stackTrace);
      
      hasError.value = true;
      errorMessage.value = error.message;
      if (error is AppError) {
        errorCode.value = error.code.toString();
      } else {
        errorCode.value = AppErrorCode.unknown.toString();
      }
    }
  }

  Future<void> translateRecordedAudio(String audioPath) async {
    // debugPrint('TranslationController: 开始翻译录音');
    isTranslating.value = true;    
    hasError.value = false;
    errorMessage.value = '';
    errorCode.value = '';           
    
    try {
      // 播放等待提示音（非阻塞）
      audioStarted.value = true;
      SystemSound.playWaitingSound();
      
      // 创建新的 StreamController 用于本次音频播放
      audioStreamController?.close();  
      audioStreamController = StreamController<List<int>>();
      // debugPrint('TranslationController: 创建新的音频流控制器');
      // 如果已经退出的话，不再调用后端
      if(isExit.value) {
        return;
      }
      await for (final response in _translationService.translateAudio(
        audioPath,
        sourceLanguage.code,
        targetLanguage.code,
      )) {
        // 清理本次录音文件
        audioUtils.cleanupRecordingFile();
        
        // 收到第一个响应时停止提示音
        if (audioStarted.value) {
          await SystemSound.stopSound();
          audioStarted.value = false;
        }
        // debugPrint('收到翻译响应，类型: ${response.type}');
        isTranslating.value = false;
        
        switch (response.type) {
          case TranslationResponseType.transcription:
            final text = response.data as String;
            // debugPrint('设置转录文本: $text');
            transcription.value = text;
            break;
            
          case TranslationResponseType.translation:
            final text = response.data as String;
            // debugPrint('设置翻译文本: $text');
            translatedText.value = text;
            break;
            
          case TranslationResponseType.audioChunk:
            final audioData = response.data as List<int>;
            // debugPrint('收到音频数据块，大小: ${audioData.length}字节');
            
            final controller = audioStreamController;
            if (controller != null) {
              // 如果是第一次收到音频数据，启动播放
              if (!isAudioPlaybackStarted.value) {
                // debugPrint('首次收到音频，开始播放流');
                isAudioPlaybackStarted.value = true;
                unawaited(audioUtils.playback(controller.stream));
              }
              
              // debugPrint('添加音频数据到流');
              controller.add(audioData);
            }
            break;
            
          case TranslationResponseType.audioEnd:
            // debugPrint('收到音频结束标记，等待音频播放完成');
            await audioStreamController?.close();
            await audioUtils.markStreamEnd();  // 标记音频流结束
            isAudioPlaybackStarted.value = false;  // 重置播放状态
            // debugPrint('音频播放完成');
            break;
            
          case TranslationResponseType.error:
            final error = response.data;
            String errorMessage;
            String errorCode;
            
            if (error is AppError) {
              errorMessage = error.message;
              errorCode = error.code.toString();
            } else if (error is String) {
              errorMessage = error;
              errorCode = AppErrorCode.unknown.toString();
            } else {
              errorMessage = '未知错误';
              errorCode = AppErrorCode.unknown.toString();
            }
            
            debugPrint('翻译错误: $errorMessage');
            hasError.value = true;
            this.errorMessage.value = errorMessage;
            this.errorCode.value = errorCode;
            break;
            
          case TranslationResponseType.audioStart:
            // debugPrint('收到音频开始标记，等待音频数据');
            break;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 翻译过程出错 - $e');
      debugPrint('Stack trace: $stackTrace');
      
      // 清理本次录音文件
      audioUtils.cleanupRecordingFile();
      
      final error = e is AppError ? e : ErrorHandler.createError(AppErrorCode.translationFailed, e);
      ErrorHandler.handleError(error, stackTrace);
      
      hasError.value = true;
      errorMessage.value = error.message;
      if (error is AppError) {
        errorCode.value = error.code.toString();
      } else {
        errorCode.value = AppErrorCode.unknown.toString();
      }
    } finally {      
      isTranslating.value = false;      
    }
  }
}