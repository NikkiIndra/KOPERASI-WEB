import 'package:get/get.dart';

import '../../nasabah/controllers/nasabah_controller.dart';

class NavigationController extends GetxController {
  final controller = Get.find<NasabahController>();
  var currentIndex = 0.obs;

  List<String> menuItems = ['Documents', 'Users'];

  void changePage(int index) {
    controller.search.value = "";
    currentIndex.value = index;
  }
}
