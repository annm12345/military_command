import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:militarycommand/views/authscreen/login.dart';
import 'package:militarycommand/views/profile/user.dart';
import 'package:militarycommand/views/profile/usercontroller.dart';

class Profile extends StatelessWidget {
  final UserController userController = Get.find();

  Profile() {
    // Fetch user details when Profile widget is initialized
    fetchUserDetails();
  }

  void fetchUserDetails() async {
    try {
      await userController
          .fetchUserDetails(userController.loggedInUser.value?.email ?? '');
    } catch (e) {
      print('Error fetching user details: $e');
    }
  }

  void handleLogout() {
    // Perform logout actions here, such as clearing user data and navigating to Auth view
    // For demonstration purposes, let's clear the user data
    userController.setUser(null); // Clearing user data
    Get.offAll(() =>
        AuthPage()); // Navigate to Auth view and remove all previous routes
  }

  @override
  Widget build(BuildContext context) {
    User? user = userController.loggedInUser.value;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blueAccent,
              Colors.indigo,
              Colors.deepPurple,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40), // Top spacing for avatar
                Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: Text(
                      user?.name?.isNotEmpty == true ? user!.name![0] : '',
                      style: TextStyle(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                buildListTile(Icons.person, 'Name', user?.name),
                buildListTile(Icons.military_tech, 'Rank', user?.rank),
                buildListTile(Icons.badge, 'BC', user?.bc),
                buildListTile(Icons.business, 'Unit', user?.unit),
                buildListTile(
                    Icons.center_focus_weak, 'Command', user?.command),
                buildListTile(Icons.email, 'Email', user?.email),
                buildListTile(Icons.phone, 'Mobile', user?.mobile),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: handleLogout,
        label: Text('Logout'),
        icon: Icon(Icons.logout),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget buildListTile(IconData icon, String title, String? subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle ?? '',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}
