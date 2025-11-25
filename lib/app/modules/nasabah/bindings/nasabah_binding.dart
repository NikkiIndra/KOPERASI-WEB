import 'package:get/get.dart';

import '../controllers/nasabah_controller.dart';

class NasabahBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NasabahController>(
      () => NasabahController(),
    );
  }
}
