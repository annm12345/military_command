import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:militarycommand/views/profile/usercontroller.dart';
import 'package:militarycommand/views/splash_screen/splash.dart'; // Import SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final UserController userController = Get.put(UserController());
  await userController.loadUserFromPreferences();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
