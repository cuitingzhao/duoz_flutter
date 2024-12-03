import 'dart:async';
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
  final _isPlaying = ValueNotifier<bool>(false);
  StreamSubscription<PlayerState>? _playerStateSubscription;
  String? recordedFilePath;
  
  // 音频源管理
  ConcatenatingAudioSource? _playlist;
  List<int> _buffer = [];
  static const _minBufferSize = 12000; // 约3个块的大小
  bool _isFirstChunk = true;
  Timer? _bufferingDebounceTimer;
  bool _isStreamEnded = false;  // 新增：标记流是否结束

  /// 获取播放状态
  bool get isPlaying => _isPlaying.value;

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

    /// 播放音频流
  /// [audioStream] 是后端返回的音频数据流
  Future<void> playback(Stream<List<int>> audioStream) async {
    debugPrint('[AudioUtils] Starting playback of audio stream');    
    
    await for (final chunk in audioStream) {
      debugPrint('[AudioUtils] Received new chunk from stream');
      await addToQueue(chunk);
    }
    debugPrint('[AudioUtils] Audio stream completed');
  }

  /// 添加音频数据到播放列表
  Future<void> addToQueue(List<int> audioData) async {
    debugPrint('[AudioUtils] Received chunk: ${audioData.length} bytes');
    
    // 添加到缓冲区
    _buffer.addAll(audioData);
    debugPrint('[AudioUtils] Current buffer size: ${_buffer.length} bytes');

    // 处理缓冲区
    if (_buffer.length >= _minBufferSize || (_isStreamEnded && _buffer.isNotEmpty)) {
      await _processBuffer();
    }
  }

  /// 处理缓冲的音频数据
  Future<void> _processBuffer() async {
    try {
      if (_buffer.isEmpty) return;

      final currentBuffer = List<int>.from(_buffer);
      _buffer.clear(); // 立即清空缓冲区，避免数据重复

      debugPrint('[AudioUtils] Processing buffer: ${currentBuffer.length} bytes');
      final audioSource = Mp3StreamAudioSource(Uint8List.fromList(currentBuffer));
      
      if (_isFirstChunk) {
        _isFirstChunk = false;
        debugPrint('[AudioUtils] Creating initial playlist');
        _playlist = ConcatenatingAudioSource(children: [audioSource]);
        await audioPlayer.setAudioSource(_playlist!, preload: true);
        _isPlaying.value = true;
        await audioPlayer.play();
      } else {
        debugPrint('[AudioUtils] Adding to existing playlist');
        await _playlist?.add(audioSource);
      }
      
    } catch (e) {
      debugPrint('[AudioUtils] Error processing buffer: $e');
      rethrow;
    }
  }

  /// 标记流结束并处理剩余数据
  Future<void> markStreamEnd() async {
    debugPrint('[AudioUtils] Marking stream as ended');
    _isStreamEnded = true;
    if (_buffer.isNotEmpty) {
      await _processBuffer();
    }
  }

  /// 清理资源
  Future<void> _cleanup() async {
    _buffer.clear();
    await _playlist?.clear();
    _playlist = null;
    _bufferingDebounceTimer?.cancel();
    _isStreamEnded = false;
  }

  /// 停止播放
  Future<void> stopPlayback() async {
    debugPrint('[AudioUtils] Stopping playback');
    _isPlaying.value = false;
    _isFirstChunk = true;
    await _cleanup();
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;
    await audioPlayer.stop();
  }

  /// 释放资源
  Future<void> dispose() async {
    await stopPlayback();
    await audioPlayer.dispose();
    await audioRecorder.dispose();
    _isPlaying.value = false;    
    _recordingPath = null;
    recordedFilePath = null;
  }



  /// 获取播放状态流
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;
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