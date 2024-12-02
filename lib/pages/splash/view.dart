import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controller.dart';

class SplashView extends GetView<SplashController> {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(() => Text(
          controller.environmentDescription,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        )),
      ),
    );
  }
}