// services/drive_auth_service.dart
import 'dart:async';
import 'dart:js' as js;
import 'package:get/get.dart';

class DriveAuthService extends GetxService {
  static DriveAuthService get to => Get.find();
  
  final isLoggedIn = false.obs;
  String? _accessToken;
  
  Future<String?> getAccessToken() async {
    final completer = Completer<String?>();
    js.context['setDriveAccessToken'] = (token) {
      completer.complete(token);
      _accessToken = token;
      isLoggedIn.value = token != null;
    };
    js.context.callMethod('googleDriveLogin', ['setDriveAccessToken']);
    return completer.future;
  }
  
  Future<bool> login() async {
    try {
      final token = await getAccessToken();
      if (token != null) {
        _accessToken = token;
        isLoggedIn.value = true;
        return true;
      }
      return false;
    } catch (e) {
      print('Google Drive login error: $e');
      return false;
    }
  }
  
  void logout() {
    _accessToken = null;
    isLoggedIn.value = false;
  }
  
  String? get accessToken => _accessToken;
}