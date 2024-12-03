import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/errors/translation_errors.dart';
import '../../data/models/language.dart';
import '../../utils/audio_utils.dart';
import '../../utils/noise_analyzer.dart';
import '../../data/services/translation_service.dart';
import 'package:record/record.dart';

class TranslationController extends GetxController {
  late final AudioPlayer _audioPlayer;
  late final AudioRecorder _audioRecorder;
  late final AudioUtils audioUtils;
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

  StreamSubscription<double>? _volumeSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void onInit() {
    super.onInit();
    debugPrint('TranslationController: 初始化');
    try {
      // 初始化音频相关组件
      _audioPlayer = AudioPlayer();
      _audioRecorder = AudioRecorder();
      audioUtils = AudioUtils(_audioPlayer, _audioRecorder);
      
      // 从路由参数中获取语言设置
      final args = Get.arguments as Map<String, dynamic>;
      sourceLanguage = args['sourceLanguage'] as Language;
      targetLanguage = args['targetLanguage'] as Language;
      debugPrint('TranslationController: 语言设置 - 源语言: ${sourceLanguage.code}, 目标语言: ${targetLanguage.code}');

      // 监听音频播放状态
      _playerStateSubscription = _audioPlayer.playerStateStream.listen(
        (state) {          
          debugPrint('TranslationController: 播放状态变更 - playing: ${state.playing}, state: ${state.processingState}');
          if (state.processingState == ProcessingState.completed) {            
            debugPrint('TranslationController: 播放完成');
          }
        },
        onError: (error) {
          debugPrint('TranslationController: 播放状态监听错误 - $error');
        },
      );

      // 自动开始录音
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        debugPrint('TranslationController: 准备自动开始录音');
        await startRecording();
      });
    } catch (e, stackTrace) {
      debugPrint('TranslationController: 初始化错误 - $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  void onClose() {
    debugPrint('TranslationController: 关闭控制器');
    _volumeSubscription?.cancel();
    _playerStateSubscription?.cancel();
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
      
      // 开始监听音量
      _volumeSubscription?.cancel();
      _volumeSubscription = NoiseAnalyzer.volumeStream.listen(
        (volume) {
          currentVolume.value = volume;
          debugPrint('TranslationController: 当前音量 - $volume');
        },
        onError: (error) {
          debugPrint('TranslationController: 音量监听错误 - $error');
        },
      );
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
      _volumeSubscription?.cancel();
      _volumeSubscription = null;
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
      final audioStreamController = StreamController<List<int>>();
      
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
              unawaited(audioUtils.playback(audioStreamController.stream));
            }
            
            debugPrint('添加音频数据到流');
            audioStreamController.add(audioData);
            break;
            
          case TranslationResponseType.error:
            debugPrint('收到错误: ${response.data}');
            throw Exception(response.data);
            
          case TranslationResponseType.audioStart:
            debugPrint('收到音频开始标记，等待音频数据');
            break;
        }
      }
      
      debugPrint('翻译流程完成，等待音频播放完成');
      // 添加一个小延迟，确保最后的音频块被处理
      await Future.delayed(const Duration(milliseconds: 500));
      // while (audioUtils.hasAudioPendingOrPlaying()) {
      //   debugPrint('等待音频播放完成...');
      //   await Future.delayed(const Duration(milliseconds: 100));
      // }
      debugPrint('音频播放完成，关闭音频流');
      await audioStreamController.close();
      
    } catch (e) {
      debugPrint('翻译过程出错: $e');
      rethrow;
    } finally {
      isTranslating.value = false;
      debugPrint('翻译过程结束');
    }
  }  

}