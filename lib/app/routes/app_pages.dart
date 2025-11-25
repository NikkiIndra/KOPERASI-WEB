import 'package:get/get.dart';

import '../modules/nasabah/bindings/nasabah_binding.dart';
import '../modules/nasabah/views/nasabah_view.dart';
import '../modules/Document/bindings/document_binding.dart';
import '../modules/Document/views/document_view.dart';
import '../modules/navigation/bindings/navigation_binding.dart';
import '../modules/navigation/views/navigation_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.NAVIGATION;

  static final routes = [
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
  ];
}
