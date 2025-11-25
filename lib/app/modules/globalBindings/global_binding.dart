import 'package:get/get.dart';
import 'package:koperasi/app/modules/Document/controllers/document_controller.dart';
import 'package:koperasi/app/modules/navigation/controllers/navigation_controller.dart';

import '../nasabah/controllers/nasabah_controller.dart';

class GlobalBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NasabahController>(() => NasabahController(), fenix: true);
    Get.lazyPut<DocumentController>(() => DocumentController(), fenix: true);
    Get.lazyPut<NavigationController>(
      () => NavigationController(),
      fenix: true,
    );
  }
}
