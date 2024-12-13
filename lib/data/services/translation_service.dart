import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../../core/config/api_config.dart';
import 'package:duoz_flutter/core/errors/error_codes.dart';
import 'package:duoz_flutter/core/errors/error_handler.dart';

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
        ).catchError((error) {
          throw ErrorHandler.createError(AppErrorCode.fileReadFailed, error);
        }),
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
      ).catchError((error) {
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.sendTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            throw ErrorHandler.createError(AppErrorCode.networkError, error);
        }
        throw ErrorHandler.createError(AppErrorCode.serverError, error);
      });
      
      debugPrint('收到响应流');
      final responseStream = response.data.stream as Stream<List<int>>;
      List<int> buffer = [];
      bool isReadingContent = false;
      int contentLength = 0;
      String? contentType;
      String? boundary;
      
      await for (final chunk in responseStream) {
        debugPrint('收到数据块: ${chunk.length} 字节');
        buffer.addAll(chunk);
        debugPrint('当前缓冲区大小: ${buffer.length} 字节');
                
        // 如果还没找到边界，先找边界
        if (boundary == null) {
          final data = utf8.decode(buffer, allowMalformed: true);
          debugPrint('尝试查找边界，当前数据: $data');
          final boundaryMatch = RegExp(r'--([^\r\n]+)').firstMatch(data);
          if (boundaryMatch != null) {
            boundary = boundaryMatch.group(1);
            debugPrint('找到边界标记: $boundary');
          } else {
            debugPrint('未找到边界标记，继续等待数据');
            continue;
          }
        }
        
        while (buffer.isNotEmpty) {
          if (!isReadingContent) {
            // 如果缓冲区太小，可能是最后的结束标记，直接返回
            if (buffer.length < 10) {
              debugPrint('剩余少量数据（${buffer.length}字节），可能是结束标记，结束处理');
              return;
            }
            
            // 查找头部结束标记
            final headerEndIndex = findSequence(buffer, utf8.encode('\r\n\r\n'));
            if (headerEndIndex == -1) {
              debugPrint('未找到头部结束标记，等待更多数据');
              break;
            }
            
            // 解析头部
            final headerStr = utf8.decode(buffer.sublist(0, headerEndIndex));
            //debugPrint('收到头部:\n$headerStr');
            
            // 检查是否是结束标记
            if (headerStr.contains('--$boundary--')) {
              debugPrint('收到结束标记');
              return;
            }
            
            // 提取 Content-Type 和 Content-Length
            final headers = parseHeaders(headerStr);
            contentType = headers['content-type'];
            contentLength = int.tryParse(headers['content-length'] ?? '') ?? 0;
            // debugPrint('解析头部 - Content-Type: $contentType, Content-Length: $contentLength');
            
            // 移除头部，保留内容
            buffer = buffer.sublist(headerEndIndex + 4);
            // debugPrint('移除头部后的缓冲区大小: ${buffer.length} 字节');
            isReadingContent = true;
          }
          
          if (isReadingContent && contentLength > 0) {
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
                    debugPrint('收到转录文本: $transcription');
                    yield TranslationResponse.transcription(transcription);
                    break;
                  case 'translation':
                    final translation = jsonData['data'] as String;
                    debugPrint('收到翻译文本: $translation');
                    yield TranslationResponse.translation(translation);
                    break;
                  case 'audio_start':
                    debugPrint('收到音频开始标记');
                    yield TranslationResponse.audioStart();
                    break;
                  case 'audio_end':
                    debugPrint('收到音频结束标记');
                    yield TranslationResponse.audioEnd();
                    break;
                  case 'error':
                    final errorMsg = jsonData['message'] as String;
                    final errorCode = jsonData['error_code'] as String? ?? 'UNKNOWN_ERROR';
                    debugPrint('收到错误消息: $errorMsg (code: $errorCode)');
                    
                    AppErrorCode appErrorCode;
                    switch (errorCode) {
                      case 'EMPTY_TRANSCRIPTION':
                        appErrorCode = AppErrorCode.noiseThresholdNotMet;
                        break;
                      case 'LANGUAGE_DETECTION_ERROR':
                        appErrorCode = AppErrorCode.unsupportedLanguage;
                        break;
                      case 'LANGUAGE_MISMATCH':
                        appErrorCode = AppErrorCode.languageMismatch;
                        break;
                      case 'INVALID_AUDIO_FORMAT':
                        appErrorCode = AppErrorCode.audioInitializationFailed;
                        break;
                      case 'OPENAI_SERVICE_ERROR':
                      case 'AZURE_SERVICE_ERROR':
                        appErrorCode = AppErrorCode.translationFailed;
                        break;
                      default:
                        appErrorCode = AppErrorCode.unknown;
                    }
                    
                    throw ErrorHandler.createError(appErrorCode, errorMsg);
                }
              } else if (contentType == 'audio/mpeg') {
                debugPrint('收到MP3音频数据块: ${content.length} 字节');
                yield TranslationResponse.audioChunk(content);
              }
              
              // 移除已处理的内容和尾部的 \r\n
              final endOfContent = contentLength + 2; // +2 for \r\n
              if (buffer.length >= endOfContent) {
                buffer = buffer.sublist(endOfContent);
                debugPrint('处理完内容后的缓冲区大小: ${buffer.length} 字节');
              } else {
                buffer = [];
              }
              isReadingContent = false;
              contentLength = 0;
              contentType = null;
            } else {
              debugPrint('等待更多数据: ${buffer.length} < $contentLength');
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
  
  factory TranslationResponse.audioEnd() => 
    TranslationResponse._(TranslationResponseType.audioEnd, null);
  
  factory TranslationResponse.error(String message) => 
      TranslationResponse._(TranslationResponseType.error, message);
}

enum TranslationResponseType {
  transcription,
  translation,
  audioChunk,
  audioStart,
  audioEnd, 
  error,
}
