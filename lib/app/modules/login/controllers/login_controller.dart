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

  void togglePassword() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRemember(bool value) {
    rememberMe.value = value;
  }

  Future<void> submit() async {
    if (formKey.currentState?.validate() != true) return;

    LoadingHelper.show(message: "Checking...");

    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // rasa halus saat load

    // validasi berdasarkan username dan password
    final username = emailController.text.trim();
    final password = passwordController.text.trim();

    const fixedUsername = "koperasi";
    const fixedPassword = "koperasi123";
    const mappedEmail = "koperasi@kita.com";

    if (username != fixedUsername || password != fixedPassword) {
      LoadingHelper.hide();
      AppToast.show("Username atau password salah");
      return;
    }

    try {
      await auth.signInWithEmailAndPassword(
        email: mappedEmail,
        password: fixedPassword,
      );

      LoadingHelper.hide();
      Get.toNamed('/navigation');
    } catch (e) {
      LoadingHelper.hide();
      AppToast.show("Login gagal");
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
