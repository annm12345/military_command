import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:militarycommand/views/home/home.dart';
import 'package:militarycommand/views/profile/user.dart';
import 'dart:convert';

import 'package:militarycommand/views/profile/usercontroller.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool isLogin = true;
  Uint8List? _imageBytes;
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController rankController = TextEditingController();
  TextEditingController idController = TextEditingController();
  TextEditingController unitController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  TextEditingController codeController = TextEditingController();
  TextEditingController commandController = TextEditingController();

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      setState(() {
        _imageBytes = result.files.single.bytes;
      });
    }
  }

  Future<void> _submit() async {
    if (!isLogin) {
      if (nameController.text.isEmpty ||
          rankController.text.isEmpty ||
          idController.text.isEmpty ||
          unitController.text.isEmpty ||
          emailController.text.isEmpty ||
          mobileController.text.isEmpty ||
          passwordController.text.isEmpty ||
          confirmPasswordController.text.isEmpty) {
        _showAlert('Error', 'Please fill in all fields.');
        return;
      }

      if (passwordController.text != confirmPasswordController.text) {
        _showAlert('Error', 'Passwords do not match.');
        return;
      }
    } else {
      if (emailController.text.isEmpty ||
          passwordController.text.isEmpty ||
          codeController.text.isEmpty) {
        _showAlert('Error', 'Please fill in all fields.');
        return;
      }
    }

    final url = Uri.parse(isLogin
        ? 'http://militarycommand.atwebpages.com/login.php'
        : 'http://militarycommand.atwebpages.com/signup.php');

    var request = http.MultipartRequest('POST', url)
      ..fields['email'] = emailController.text
      ..fields['password'] = passwordController.text
      ..fields['code'] = codeController.text;

    if (!isLogin) {
      request.fields['name'] = nameController.text;
      request.fields['rank'] = rankController.text;
      request.fields['id'] = idController.text;
      request.fields['unit'] = unitController.text;
      request.fields['mobile'] = mobileController.text;
      request.fields['password'] = confirmPasswordController.text;
      request.fields['command'] = commandController.text;
    }

    try {
      var response = await request.send();

      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        final jsonResponse = json.decode(responseData);

        if (jsonResponse['success']) {
          if (isLogin) {
            // Assuming jsonResponse['user'] contains user details
            UserController userController = Get.find();
            userController.setUser(User(
              name: nameController.text,
              rank: rankController.text,
              bc: idController.text,
              unit: unitController.text,
              email: emailController.text,
              mobile: mobileController.text,
              command: mobileController.text,
            ));
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const Home()),
            );
          } else {
            _showAlert('Success', jsonResponse['message'],
                isSignupSuccess: true);
          }
        } else {
          _showAlert('Error', jsonResponse['message']);
        }
      } else {
        _showAlert('Error', 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showAlert('Error', 'An error occurred: $e');
    }
  }

  void _showAlert(String title, String message,
      {bool isSignupSuccess = false}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (isSignupSuccess) {
                  setState(() {
                    isLogin = true;
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(33, 219, 243, 0.686),
              Color.fromARGB(255, 141, 245, 189),
              Color.fromARGB(255, 222, 223, 191)
            ],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Card(
              elevation: 8.0,
              margin: EdgeInsets.all(20.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      isLogin ? 'Login' : 'Sign Up',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    if (!isLogin) ...[
                      TextField(
                        controller: idController,
                        decoration: InputDecoration(
                          labelText: 'ပြန်တမ်းဝင်အမှတ်',
                          hintText: 'ကြည်း ၁၂၃၄၅',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.boy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: rankController,
                        decoration: InputDecoration(
                          labelText: 'အဆင့် ၊ ရာထူး',
                          hintText:
                              'ဒုတိယဗိုလ်မှူးကြီး ၊ တပ်ရင်းမှူး(အတိုကောက်မသုံးရ)',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.boy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'အမည်',
                          hintText: 'မောင်ဘ(မြန်မာလိုရေးသွင်းပါ)',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.boy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: unitController,
                        decoration: InputDecoration(
                          labelText: 'တပ်',
                          hintText: 'အမှတ်(၁)ခြေလျင်တပ်ရင်း(အတိုကောက်မသုံးရ)',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.boy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: commandController,
                        decoration: InputDecoration(
                          labelText: 'ကွပ်ကဲမှု၊ တိုင်း',
                          hintText:
                              'အရှေ့ပိုင်းတိုင်းစစ်ဌာနချုပ်(အတိုကောက်မသုံးရ)',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.boy),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                      TextField(
                        controller: mobileController,
                        decoration: InputDecoration(
                          labelText: 'ဖုန်းနံပါတ်',
                          hintText: 'ဖုန်းနံပါတ်ထည့်ပါ',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                    ],
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'အီးမေးလ်',
                        hintText: 'example@domain.com',
                        hintStyle: TextStyle(color: Colors.red),
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    SizedBox(height: 20.0),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'စကားဝှက်',
                        hintText: 'စကားဝှက်ထည့်ပါ',
                        hintStyle: TextStyle(color: Colors.red),
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                    ),
                    if (isLogin) ...[
                      SizedBox(height: 20.0),
                      TextField(
                        controller: codeController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'admin ၏ အတည်ပြုကုဒ်ထည့်ပါ ',
                          hintText: '0000000',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                    ],
                    if (!isLogin) ...[
                      SizedBox(height: 20.0),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'စကားဝှက်ကိုအတည်ပြုပါ',
                          hintText: 'စကားဝှက်ကိုအတည်ပြုပါ',
                          hintStyle: TextStyle(color: Colors.red),
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.0),
                    ],
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isLogin ? 'Login' : 'Sign Up'),
                    ),
                    SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(isLogin
                          ? 'Create an account'
                          : 'Already have an account?'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
