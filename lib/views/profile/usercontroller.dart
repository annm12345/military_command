import 'dart:convert';
import 'package:get/get.dart';
import 'package:militarycommand/views/profile/user.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserController extends GetxController {
  Rx<User?> loggedInUser = Rx<User?>(null);

  void setUser(User? user) {
    loggedInUser.value = user;
    if (user != null) {
      _saveUserToPreferences(user);
    } else {
      _clearUserFromPreferences();
    }
  }

  Future<void> fetchUserDetails(String email) async {
    try {
      final response = await http.post(
        Uri.parse('http://militarycommand.atwebpages.com/login_userdetail.php'),
        body: {'email': email},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('error')) {
          throw Exception(jsonResponse['error']);
        } else {
          User user = User.fromJson(
              jsonResponse); // Assuming fromJson is correctly implemented
          setUser(user);
        }
      } else {
        throw Exception('Failed to load user details');
      }
    } catch (e) {
      throw Exception('Error fetching user details: $e');
    }
  }

  Future<void> _saveUserToPreferences(User user) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('user', json.encode(user.toJson()));
  }

  Future<void> _clearUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('user');
  }

  Future<void> loadUserFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    if (userData != null) {
      final userMap = json.decode(userData);
      setUser(User.fromJson(userMap));
    }
  }
}
