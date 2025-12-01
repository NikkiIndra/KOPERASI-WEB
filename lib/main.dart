import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'firebase_options.dart';
import 'app/routes/app_pages.dart';
import 'app/globalBindings/global_binding.dart';
import 'dart:js' as js;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  final firebaseConfig = js.context['firebaseConfig'];
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: firebaseConfig['apiKey'],
      authDomain: firebaseConfig['authDomain'],
      projectId: firebaseConfig['projectId'],
      storageBucket: firebaseConfig['storageBucket'],
      messagingSenderId: firebaseConfig['messagingSenderId'],
      appId: firebaseConfig['appId'],
    ),
  );
  
  // Initialize GetX dengan services
  runApp(
    GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Koperasi App",
      initialBinding: GlobalBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
    ),
  );
}
