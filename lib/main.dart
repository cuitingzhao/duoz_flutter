import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/routes/app_pages.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter绑定初始化
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DuoZ Flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
