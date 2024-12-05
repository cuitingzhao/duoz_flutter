import 'dart:async';
import 'dart:math';
import 'dart:io';
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
  
  // 音频源管理
  ConcatenatingAudioSource? _playlist;
  List<int> _buffer = [];
  static const _minBufferSize = 8000; // 约3个块的大小
  bool _isFirstChunk = true;
  Timer? _bufferingDebounceTimer;
  bool _isStreamEnded = false;  // 新增：标记流是否结束

  /// 获取播放状态
  bool get isPlaying => _isPlaying.value;

  /// 获取当前录音文件路径
  // String? get recordingPath => _recordingPath;


  AudioUtils(this.audioPlayer, this.audioRecorder) {
    // 监听播放器状态
    _playerStateSubscription = audioPlayer.playerStateStream.listen((state) {
      debugPrint('[AudioUtils] Player state changed: ${state.processingState}');
      debugPrint('[AudioUtils] Current volume: ${audioPlayer.volume}');
      
      switch (state.processingState) {
        case ProcessingState.completed:
          _isPlaying.value = false;     
          _resetPlayer();
          break;
        case ProcessingState.buffering:
          debugPrint('[AudioUtils] Buffering audio...');
          break;
        case ProcessingState.ready:
          print("_isPlaying.value: ${_isPlaying.value}, _isStreamEnded:  ${_isStreamEnded}");
          if (!_isPlaying.value) {
            debugPrint('[AudioUtils] Player ready, starting playback');
            audioPlayer.setVolume(1.0).then((_) {
              debugPrint('[AudioUtils] Volume set to 1.0');
              audioPlayer.play();
            });
            _isPlaying.value = true;
          }
          break;
        default:
          break;
      }
    });
  }

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
        sampleRate: 44100,            // 44.1kHz采样率
        numChannels: 1,               // 使用单声道录音，可以减少干扰
        autoGain: true,               // 启用自动增益控制
        echoCancel: true,             // 启用回声消除
        noiseSuppress: true,          // 启用噪音抑制
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
      debugPrint('[AudioUtils] Error stopping recording: $e');
      rethrow;
    }
  }  

    /// 播放音频流
  /// [audioStream] 是后端返回的音频数据流
  Future<void> playback(Stream<List<int>> audioStream) async {
    debugPrint('[AudioUtils] Starting playback of audio stream at ${DateTime.now()}');    
    
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
      // 检查小块数据的内容
      if (currentBuffer.length <= 36) {
        debugPrint('[AudioUtils] Small buffer content (hex): ${currentBuffer.map((e) => e.toRadixString(16).padLeft(2, '0')).join(' ')}');
        // 如果数据块太小，直接跳过
        debugPrint('[AudioUtils] Skipping small buffer chunk');
        return;
      }
      
      debugPrint('[AudioUtils] Current player state: ${audioPlayer.processingState}');
      debugPrint('[AudioUtils] Is stream ended: $_isStreamEnded');
      
      final audioSource = Mp3StreamAudioSource(Uint8List.fromList(currentBuffer));
      
      if (_isFirstChunk) {
        _isFirstChunk = false;
        debugPrint('[AudioUtils] Creating initial playlist');
        _playlist = ConcatenatingAudioSource(children: [audioSource]);
        await audioPlayer.setAudioSource(_playlist!, preload: true);
        await audioPlayer.setVolume(1.0);  
      } else {
        debugPrint('[AudioUtils] Adding to existing playlist');
        if (_playlist != null) {
          debugPrint('[AudioUtils] Current playlist length: ${_playlist!.length}');
        }
        await _playlist?.add(audioSource);
      }
      
    } catch (e) {
      debugPrint('[AudioUtils] Error processing buffer: $e');
      rethrow;
    }
  }

  /// 重置播放器状态
  Future<void> _resetPlayer() async {    
    _isFirstChunk = true;
    await _playlist?.clear();
    _playlist = null;
    await audioPlayer.setVolume(1.0);  // 需要添加这一行
  }

  /// 标记流结束并处理剩余数据
  Future<void> markStreamEnd() async {
    debugPrint('[AudioUtils] Marking stream as ended. Current player state: ${audioPlayer.processingState}');
    debugPrint('[AudioUtils] Current buffer size: ${_buffer.length} bytes');
    if (_playlist != null) {
      debugPrint('[AudioUtils] Current playlist length: ${_playlist!.length}');
    }
    _isStreamEnded = true;    
    if (_buffer.isNotEmpty) {
      debugPrint('[AudioUtils] Processing final buffer');
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
    
    await _cleanup();
    await _playerStateSubscription?.cancel();
    _playerStateSubscription = null;    
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
    await stopPlayback();
    await audioPlayer.dispose();
    await audioRecorder.dispose();
    await cleanupRecordingFile();  // 使用公开方法
    _isPlaying.value = false;
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
    //print('[Mp3StreamAudioSource] Requesting audio data from $start to $end');
    
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