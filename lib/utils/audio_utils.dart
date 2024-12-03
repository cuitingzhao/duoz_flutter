import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 音频工具类，专注于音频录制和播放的底层操作
class AudioUtils {
  final AudioPlayer audioPlayer;
  final AudioRecorder audioRecorder;
  String? _recordingPath;
  final Queue<List<int>> _audioQueue = Queue();
  final _isPlaying = ValueNotifier<bool>(false);
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? recordedFilePath;
  
  // 添加音频块计数器
  int _pendingChunksCount = 0;

  AudioUtils(this.audioPlayer, this.audioRecorder);

  /// 初始化录音机
  Future<void> _initRecorder() async {
    final hasPermission = await audioRecorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Microphone permission not granted');
    }
  }

  /// 开始录音
  Future<void> startRecording() async {
    try {
      await _initRecorder();
      
      // 创建临时文件路径
      final dir = await getTemporaryDirectory();
      _recordingPath = path.join(dir.path, 'audio_${DateTime.now().millisecondsSinceEpoch}.wav');
      
      // 配置录音参数
      await audioRecorder.start(const RecordConfig(
        encoder: AudioEncoder.wav,    // 使用WAV编码器
        bitRate: 128000,              // 128kbps
        sampleRate: 44100,            // 44.1kHz
        numChannels: 1,               // 单声道
      ), path: _recordingPath!);
    } catch (e) {
      rethrow;
    }
  }

  /// 停止录音
  Future<String?> stopRecording() async {
    try {
      return await audioRecorder.stop();
    } catch (e) {
      rethrow;
    }
  }

  /// 检查是否正在录音
  Future<bool> isRecording() async {
    return await audioRecorder.isRecording();
  }

  /// 添加音频数据到播放队列
  Future<void> addToQueue(List<int> audioData) async {
    debugPrint('[AudioUtils] Adding audio chunk to queue. Queue size before: ${_audioQueue.length}');
    _audioQueue.add(audioData);
    _pendingChunksCount++;
    debugPrint('[AudioUtils] Audio chunk added. Queue size after: ${_audioQueue.length}, pending chunks: $_pendingChunksCount');

    if (!_isPlaying.value) {
      debugPrint('[AudioUtils] Player not playing, starting playback');
      await playNextInQueue();
    } else {
      debugPrint('[AudioUtils] Player is already playing, chunk queued for later');
    }
  }

  /// 播放队列中的下一个音频
  Future<void> playNextInQueue() async {
    if (_audioQueue.isEmpty) {
      debugPrint('[AudioUtils] Queue is empty, nothing to play');
      return;
    }

    try {
      debugPrint('[AudioUtils] Playing next audio in queue. Queue size: ${_audioQueue.length}');
      final audioData = _audioQueue.removeFirst();
      debugPrint('[AudioUtils] Audio chunk removed from queue. Remaining queue size: ${_audioQueue.length}');
      
      final audioSource = Mp3StreamAudioSource(audioData);
      
      if (_playerStateSubscription == null) {
        debugPrint('[AudioUtils] Setting up player state subscription');
        _playerStateSubscription = audioPlayer.playerStateStream.listen((state) async {
          debugPrint('[AudioUtils] Player state changed: ${state.processingState} - playing: ${state.playing}');
          if (state.processingState == ProcessingState.completed) {
            debugPrint('[AudioUtils] Audio completed, checking queue');
            _pendingChunksCount--;
            debugPrint('[AudioUtils] Chunk completed, remaining chunks: $_pendingChunksCount');
            
            if (_audioQueue.isNotEmpty) {
              debugPrint('[AudioUtils] Queue not empty, playing next chunk');
              await playNextInQueue();
            } else {
              debugPrint('[AudioUtils] Queue empty, waiting for more chunks');
              _isPlaying.value = false;
            }
          }
        });
      }

      await audioPlayer.setAudioSource(audioSource);
      _isPlaying.value = true;
      debugPrint('[AudioUtils] Starting playback of new audio chunk');
      await audioPlayer.play();
    } catch (e) {
      debugPrint('[AudioUtils] Error playing next in queue: $e');
      _pendingChunksCount--; // 如果播放失败也要减少计数
      rethrow;
    }
  }

  /// 检查是否有音频正在播放或等待播放
  bool hasAudioPendingOrPlaying() {
    final hasPendingChunks = _pendingChunksCount > 0;
    debugPrint('[AudioUtils] Checking audio status - pendingChunks: $_pendingChunksCount, '
        'isPlaying: ${_isPlaying.value}, '
        'queueNotEmpty: ${_audioQueue.isNotEmpty}, '
        'final status: $hasPendingChunks');
    return hasPendingChunks;
  }

  /// 播放音频流
  /// [audioStream] 是后端返回的音频数据流
  Future<void> playback(Stream<List<int>> audioStream) async {
    debugPrint('[AudioUtils] Starting playback of audio stream');
    await stopPlayback();
    
    await for (final chunk in audioStream) {
      debugPrint('[AudioUtils] Received new chunk from stream');
      await addToQueue(chunk);
    }
    debugPrint('[AudioUtils] Audio stream completed');
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    debugPrint('[AudioUtils] Stopping playback');
    _isPlaying.value = false;
    _audioQueue.clear();
    _pendingChunksCount = 0;
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    await audioPlayer.stop();
  }

  /// 获取播放状态流
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;

  /// 释放资源
  Future<void> dispose() async {
    debugPrint('[AudioUtils] Disposing audio utils');
    await stopPlayback();
    await audioPlayer.dispose();
    await audioRecorder.dispose();
    _isPlaying.value = false;
    _audioQueue.clear();
    _pendingChunksCount = 0;
    _recordingPath = null;
    recordedFilePath = null;
  }
}

/// 处理MP3格式的音频流
class Mp3StreamAudioSource extends StreamAudioSource {
  final List<int> _audioData;
  
  Mp3StreamAudioSource(this._audioData) : super(tag: 'Mp3StreamAudioSource');

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    print('[Mp3StreamAudioSource] Requesting audio data from $start to $end');
    
    start = start ?? 0;
    end = end ?? _audioData.length;
    
    // 计算实际的数据范围
    final length = _audioData.length;
    final offset = start;
    final count = end - start;
    
    // 创建一个包含指定范围数据的子列表
    final subData = _audioData.sublist(offset, min(offset + count, length));
    
    return StreamAudioResponse(
      sourceLength: length,
      contentLength: subData.length,
      offset: offset,
      stream: Stream.value(subData),
      contentType: 'audio/mpeg',
    );
  }
}