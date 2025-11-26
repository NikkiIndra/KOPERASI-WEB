import 'package:get/get.dart';

import '../helper/splash_screen.dart';
import '../modules/dokemenKantor/bindings/document_binding.dart';
import '../modules/dokemenKantor/views/document_view.dart';
import '../modules/dokumenGudang/bindings/dokumen_gudang_binding.dart';
import '../modules/dokumenGudang/views/dokumen_gudang_view.dart';
import '../modules/login/bindings/login_binding.dart';
import '../modules/login/views/login_view.dart';
import '../modules/nasabah/bindings/nasabah_binding.dart';
import '../modules/nasabah/views/nasabah_view.dart';
import '../modules/navigation/bindings/navigation_binding.dart';
import '../modules/navigation/views/navigation_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.LOGIN;

  static final routes = [
    GetPage(
      name: '/',
      page: () => const SplashView(),
    ),
    GetPage(
      name: _Paths.HOME,
      page: () => const DocumentView(),
      binding: DocumentBinding(),
    ),
    GetPage(
      name: _Paths.NAVIGATION,
      page: () => const NavigationView(),
      binding: NavigationBinding(),
    ),
    GetPage(
      name: _Paths.USER_LIST,
      page: () => const NasabahView(),
      binding: NasabahBinding(),
    ),
    GetPage(
      name: _Paths.DOKUMEN_GUDANG,
      page: () => const DokumenGudangView(),
      binding: DokumenGudangBinding(),
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
  ];
}
