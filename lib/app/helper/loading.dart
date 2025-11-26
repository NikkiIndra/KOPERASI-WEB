import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoadingHelper {
  static bool _isShowing = false;

  static void show({String? message}) {
    if (_isShowing) return;
    _isShowing = true;

    Get.dialog(
      WillPopScope(
        onWillPop: () async => false, // tidak bisa back
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    message!,
                    style: const TextStyle(fontSize: 16),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  static void hide() {
    if (_isShowing) {
      _isShowing = false;
      Get.back();
    }
  }
}
