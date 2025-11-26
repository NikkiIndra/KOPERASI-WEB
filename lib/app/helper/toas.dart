import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppToast {
  static void show(String message, {Color bgColor = Colors.black87}) {
    // Ambil overlay dari root navigator (bukan context dialog)
    final overlayContext = Get.overlayContext ?? Get.context;

    if (overlayContext == null) return;

    final ctx = Get.overlayContext ?? Get.context!;
    final overlay = Overlay.of(ctx);

    if (overlay == null) return;

    final entry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 2), () {
      entry.remove();
    });
  }
}
