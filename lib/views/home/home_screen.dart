import 'package:flutter/material.dart';
import 'package:militarycommand/controllers/home_controller.dart';
import 'package:militarycommand/home_buttoms.dart';
import 'package:militarycommand/views/map/map.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:militarycommand/colors.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:militarycommand/images.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('onStatus: $val');
          if (val == 'done') {
            _postSpeech(_text);
          }
        },
        onError: (val) {
          print('onError: $val');
          setState(() {
            _isListening = false;
          });
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _text = val.recognizedWords;
            });
            if (_text.length >= 5) {
              _speech.stop();
              _postSpeech(_text);
            }
          },
          localeId: 'my_MM', // Burmese language code
          listenFor: Duration(seconds: 7), // Max listening duration
        );
      } else {
        setState(() => _isListening = false);
        _speech.stop();
        _postSpeech(_text);
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      _postSpeech(_text);
    }
  }

  Future<void> _postSpeech(String text) async {
    if (text.isNotEmpty) {
      final url =
          'https://militaryvoicecommand.000webhostapp.com/text.php?transcript=$text';
      print('Posting to URL: $url');
      try {
        final response = await http.get(Uri.parse(url));
        print('HTTP response status: ${response.statusCode}');
        if (response.statusCode == 200) {
          print('Response: ${response.body}');
          // Check if the response body equals "မြေပုံ"
          if (response.body.trim() == '"မြေပုံ"') {
            // Navigate to MapPage using GetX
            var controller = Get.find<HomeController>();
            controller.updateIndex(1);
            // Restart listening if needed
            _listen();
          } else if (response.body.trim() == '"ကြေးနန်း"') {
            var controller = Get.find<HomeController>();
            controller.updateIndex(2);
            // Restart listening if needed
            _listen();
          } else {
            _listen();
          }
        } else {
          print('Error: ${response.statusCode}');
          _listen();
        }
      } catch (e) {
        print('Exception: $e');
        _listen();
      }
    } else {
      print('No text to post.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(12),
          width: context.screenWidth,
          height: context.screenHeight,
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                height: 60,
                color: lightGrey,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          suffixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: whiteColor,
                          border: InputBorder.none,
                          hintText: "Search Anything",
                          hintStyle: TextStyle(color: textfieldGrey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Swipper brands
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          2,
                          (index) => HomeButtom(
                            height: context.screenHeight * 0.13,
                            width: context.screenWidth / 2.5,
                            icon: index == 0 ? icforce : icmission,
                            title: index == 0 ? "တပ်များ" : "စစ်ဦးစီး",
                          ),
                        ),
                      ),
                      20.heightBox,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          2,
                          (index) => HomeButtom(
                            height: context.screenHeight * 0.13,
                            width: context.screenWidth / 2.5,
                            icon: index == 0 ? icforce : icmission,
                            title: index == 0 ? "စစ်ရေး" : "စစ်ထောက်",
                          ),
                        ),
                      ),
                      // Additional swiper content can go here
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _listen,
      //   child: Icon(_isListening ? Icons.mic : Icons.mic_none),
      // ),
      bottomSheet: _text.isNotEmpty
          ? Container(
              color: Colors.black54,
              padding: EdgeInsets.all(16),
              child: Text(
                _text,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : null,
    );
  }
}
