import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../helper/loading.dart';
import '../../../helper/toas.dart';

class LoginController extends GetxController {
  final formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isPasswordVisible = false.obs;
  var rememberMe = false.obs;

  final auth = FirebaseAuth.instance;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // Method untuk reset controller tanpa dispose
  void resetControllers() {
    emailController.clear();
    passwordController.clear();
    isPasswordVisible.value = false;
    rememberMe.value = false;
  }

  void togglePassword() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRemember(bool value) {
    rememberMe.value = value;
  }

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;

    LoadingHelper.show(message: "Checking...");

    await Future.delayed(const Duration(milliseconds: 300));

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      LoadingHelper.hide();
      Get.offAllNamed('/navigation');
    } catch (e) {
      LoadingHelper.hide();
      print("Login failed: $e");
      // AppToast.show("Login gagal: ${e.toString()}");
    }
  }
}
