import 'package:get/get.dart';
import 'package:koperasi/app/modules/dokemenKantor/controllers/document_controller.dart';
import 'package:koperasi/app/modules/dokumenGudang/controllers/dokumen_gudang_controller.dart';
import 'package:koperasi/app/modules/login/controllers/login_controller.dart';
import 'package:koperasi/app/modules/navigation/controllers/navigation_controller.dart';

import '../modules/nasabah/controllers/nasabah_controller.dart';
import '../services/drive_auth_service.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NasabahController>(() => NasabahController(), fenix: true);
    Get.lazyPut<DocumentController>(() => DocumentController(), fenix: true);
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
    Get.lazyPut<DokumenGudangController>(
      () => DokumenGudangController(),
      fenix: true,
    );
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
    Get.lazyPut(() => DriveAuthService(), fenix: true);
  }
}
