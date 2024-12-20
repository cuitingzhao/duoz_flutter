import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import '../../utils/noise_analyzer.dart';
import '../../core/errors/error_handler.dart';
import '../../core/routes/app_pages.dart';
import '../../core/config/api_config.dart';

class SplashController extends GetxController {
  // 观察变量
  final _isAnalyzing = true.obs;
  final _environmentDescription = '正在检测环境噪音...'.obs;
  final _dio = Dio();  

  // Getters
  bool get isAnalyzing => _isAnalyzing.value;
  String get environmentDescription => _environmentDescription.value;

  @override
  void onInit() {
    super.onInit();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // 先预热网络连接
      await _warmupNetwork();     
      // 再进行噪音检测
      await _startNoiseAnalysis();
    } catch (e) {
      ErrorHandler.handleError(e);
    }
  }

  Future<void> _startNoiseAnalysis() async {
    try {      
      await NoiseAnalyzer.analyzeNoise();
      _environmentDescription.value = NoiseAnalyzer.getEnvironmentDescription();
      
      // 等待1秒让用户看到结果
      await Future.delayed(const Duration(seconds: 1));
            
    } catch (e) {
      ErrorHandler.handleError(e);
      // 出错时仍然显示分析完成，但使用默认值
      _environmentDescription.value = NoiseAnalyzer.getEnvironmentDescription();
    } finally {
      _isAnalyzing.value = false;
      // 导航到主页，并传递环境描述
      Get.offNamed(
        Routes.HOME,
        arguments: {'environmentDescription': _environmentDescription.value},
      );
    }
  }

  // 预热网络连接
  Future<void> _warmupNetwork() async {
    try {
      debugPrint("预热网络连接");
      final baseUrl = APIConfig.current.environment.baseURL;
      await _dio.get(baseUrl);
    } catch (e) {
      // 忽略预热失败
      debugPrint("预热网络连接失败:$e");
    }
  }
  
}