import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:militarycommand/views/authscreen/login.dart';
import 'package:militarycommand/views/home/home.dart';
import 'package:militarycommand/views/profile/usercontroller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserController userController = Get.find();

  @override
  void initState() {
    super.initState();
    print("SplashScreen initState called");
    changeScreen(); // Call changeScreen when the widget is initialized
  }

  // Creating a method to change screen based on login status
  void changeScreen() {
    Future.delayed(const Duration(seconds: 2), () {
      if (userController.loggedInUser.value != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => Home()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(253, 247, 246, 246),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipOval(
              child: Image.asset(
                "icon/logo.png",
                width: 200,
                height: 200,
                fit: BoxFit
                    .cover, // Ensures the image covers the entire circular area
              ),
            ),
          ],
        ),
      ),
    );
  }
}
