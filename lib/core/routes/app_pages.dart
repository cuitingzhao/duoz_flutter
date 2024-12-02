import 'package:get/get.dart';
import '../../pages/splash/binding.dart';
import '../../pages/splash/view.dart';
import '../../pages/home/binding.dart';
import '../../pages/home/view.dart';

part 'app_routes.dart';

class AppPages {
  static const INITIAL = Routes.SPLASH;

  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
  ];
}