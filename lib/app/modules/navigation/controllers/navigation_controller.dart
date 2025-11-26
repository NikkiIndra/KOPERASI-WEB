import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../helper/loading.dart';
import '../../login/views/login_view.dart';
import '../../nasabah/controllers/nasabah_controller.dart';

class NavigationController extends GetxController {
  final controller = Get.find<NasabahController>();
  var currentIndex = 0.obs;

  List<String> menuItems = ['Document Kantor', 'Document Gudang', 'Logout'];

  void changePage(int index) {
    controller.search.value = "";
    currentIndex.value = index;
  }

  Future<void> logout() async {
    LoadingHelper.show();

    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    await Future.delayed(const Duration(milliseconds: 500));

    LoadingHelper.hide();
    Get.offAll(() => const LoginView());
  }

  Future<void> confirmLogout() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text("Yakin ingin keluar dari akun ini?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );

    // Jika user memilih Yes
    if (result == true) {
      logout();
    }
  }
}
