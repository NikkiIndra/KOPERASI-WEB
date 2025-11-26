import 'package:get/get.dart';

import '../controllers/dokumen_gudang_controller.dart';

class DokumenGudangBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DokumenGudangController>(
      () => DokumenGudangController(),
    );
  }
}
