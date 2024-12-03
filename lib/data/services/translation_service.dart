import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../models/language.dart';
import '../../core/config/api_config.dart';

class TranslationService {
  final _dio = Dio();
  final _apiConfig = APIConfig.current;

  Stream<TranslationResponse> translateAudio(
    String audioPath,
    String sourceLanguage,
    String targetLanguage,
  ) async* {
    try {
      debugPrint('开始翻译音频: $audioPath');
      debugPrint('源语言: $sourceLanguage, 目标语言: $targetLanguage');
      
      final url = _apiConfig.translateAudioURL;
      debugPrint('请求URL: $url');
      
      // Prepare form data
      final formData = FormData.fromMap({
        'audio_file': await MultipartFile.fromFile(
          audioPath,
          contentType: MediaType('audio', 'mpeg'),
        ),
        'source_language': sourceLanguage,
        'target_language': targetLanguage,
      });

      debugPrint('发送请求... ${DateTime.now()}');
      // Make streaming request
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Accept': 'multipart/x-mixed-replace; boundary=frame',
          },
        ),
      );
      debugPrint('收到响应流');

      final responseStream = response.data.stream as Stream<List<int>>;
      List<int> buffer = [];
      bool isReadingContent = false;
      int contentLength = 0;
      String? contentType;
      
      await for (final chunk in responseStream) {
        debugPrint('收到数据块: ${chunk.length} 字节');
        buffer.addAll(chunk);
        debugPrint('当前缓冲区大小: ${buffer.length} 字节');
        
        while (buffer.isNotEmpty) {
          if (!isReadingContent) {
            // 查找头部结束标记
            final headerEndIndex = findSequence(buffer, utf8.encode('\r\n\r\n'));
            if (headerEndIndex == -1) {
              debugPrint('未找到头部结束标记，等待更多数据');
              break;
            }
            
            // 解析头部
            final headerStr = utf8.decode(buffer.sublist(0, headerEndIndex));
            debugPrint('收到头部:\n$headerStr');
            
            // 提取 Content-Type 和 Content-Length
            final headers = parseHeaders(headerStr);
            contentType = headers['content-type'];
            contentLength = int.tryParse(headers['content-length'] ?? '') ?? 0;
            debugPrint('解析头部 - Content-Type: $contentType, Content-Length: $contentLength');
            
            // 移除头部，保留内容
            buffer = buffer.sublist(headerEndIndex + 4);
            debugPrint('移除头部后的缓冲区大小: ${buffer.length} 字节');
            isReadingContent = true;
          }
          
          if (isReadingContent) {
            if (buffer.length >= contentLength) {
              debugPrint('有足够的数据读取内容: ${buffer.length} >= $contentLength');
              final content = buffer.sublist(0, contentLength);
              
              if (contentType == 'application/json') {
                final jsonStr = utf8.decode(content);
                debugPrint('解析JSON数据: $jsonStr');
                final jsonData = json.decode(jsonStr);
                final type = jsonData['type'];
                debugPrint('消息类型: $type');
                
                switch (type) {
                  case 'transcription':
                    final transcription = jsonData['data'] as String;
                    debugPrint('收到转录文本: $transcription at ${DateTime.now()}');
                    yield TranslationResponse.transcription(transcription);
                    break;
                  case 'translation':
                    final translation = jsonData['data'] as String;
                    debugPrint('收到翻译文本: $translation at ${DateTime.now()}');
                    yield TranslationResponse.translation(translation);
                    break;
                  case 'audio_start':
                    debugPrint('收到音频开始标记');
                    yield TranslationResponse.audioStart();
                    break;
                  case 'error':
                    final errorMsg = jsonData['message'] as String;
                    debugPrint('收到错误消息: $errorMsg');
                    throw Exception(errorMsg);
                }
              } else if (contentType == 'audio/mpeg') {
                debugPrint('收到MP3音频数据块: ${content.length} 字节');
                yield TranslationResponse.audioChunk(content);
              }
              
              // 移除已处理的内容
              buffer = buffer.sublist(contentLength + 2); // +2 for \r\n
              debugPrint('处理完内容后的缓冲区大小: ${buffer.length} 字节');
              isReadingContent = false;
            } else {
              debugPrint('等待更多数据: 当前 ${buffer.length} < 需要 $contentLength');
              break;
            }
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('翻译服务错误: $e');
      debugPrint('堆栈跟踪:\n$stackTrace');
      yield TranslationResponse.error(e.toString());
    }
  }

  Map<String, String> parseHeaders(String headerStr) {
    final headers = <String, String>{};
    for (final line in headerStr.split('\r\n')) {
      if (line.startsWith('--')) continue;  // 跳过边界行
      final parts = line.split(':');
      if (parts.length == 2) {
        headers[parts[0].trim().toLowerCase()] = parts[1].trim();
      }
    }
    return headers;
  }

  int findSequence(List<int> data, List<int> sequence) {
    for (var i = 0; i < data.length - sequence.length; i++) {
      if (listEquals(data.sublist(i, i + sequence.length), sequence)) {
        return i;
      }
    }
    return -1;
  }
}

class TranslationResponse {
  final TranslationResponseType type;
  final dynamic data;

  TranslationResponse._(this.type, this.data);

  factory TranslationResponse.transcription(String text) => 
      TranslationResponse._(TranslationResponseType.transcription, text);
  
  factory TranslationResponse.translation(String text) => 
      TranslationResponse._(TranslationResponseType.translation, text);
  
  factory TranslationResponse.audioChunk(List<int> audio) => 
      TranslationResponse._(TranslationResponseType.audioChunk, audio);
  
  factory TranslationResponse.audioStart() => 
      TranslationResponse._(TranslationResponseType.audioStart, null);
  
  factory TranslationResponse.error(String message) => 
      TranslationResponse._(TranslationResponseType.error, message);
}

enum TranslationResponseType {
  transcription,
  translation,
  audioChunk,
  audioStart,
  error,
}
