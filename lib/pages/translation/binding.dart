import 'package:get/get.dart';
import 'controller.dart';

class TranslationBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => TranslationController());
  }
}