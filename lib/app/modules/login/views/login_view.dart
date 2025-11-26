import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../../../helper/form_login.dart';
import '../../../helper/logo_login.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});
 @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: Center(
        child: isSmallScreen
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [Logo(), FormLogin()],
              )
            : Container(
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 800),
                child: const Row(
                  children: [
                    Expanded(child: Logo()),
                    Expanded(child: Center(child: FormLogin())),
                  ],
                ),
              ),
      ),
    );
  }

  
}
