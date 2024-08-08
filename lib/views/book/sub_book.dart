import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:militarycommand/colors.dart';
import 'package:militarycommand/home_buttoms.dart';
import 'package:militarycommand/images.dart';
import 'package:velocity_x/velocity_x.dart';

void main() {
  runApp(Booklist());
}

class Booklist extends StatelessWidget {
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
              // Container(
              //   alignment: Alignment.center,
              //   height: 60,
              //   color: lightGrey,
              //   child: Row(
              //     children: [
              //       Expanded(
              //         child: TextFormField(
              //           decoration: InputDecoration(
              //             suffixIcon: Icon(Icons.search),
              //             filled: true,
              //             fillColor: whiteColor,
              //             border: InputBorder.none,
              //             hintText: "Search Anything",
              //             hintStyle: TextStyle(color: textfieldGrey),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "စစ်ဦးစီးဆိုင်ရာစာအုပ်များ"
                                : "စစ်ရေးဆိုင်ရာစာအုပ်များ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "စစ်ထောက်ဆိုင်စာအုပ်များ"
                                : "စစ်နည်းဗျူဟာစာအုပ်များ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "လက်နက်ငယ်ဆိုင်ရာစာအုပ်များ"
                                : "ခြေလျင်အကူပစ်လက်နက်ကြီးများ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "အမြောက်တပ်ဖွဲ့လက်ဆွဲစာဆောင်များ"
                                : "သံချပ်ကာယန္တရားဆိုင်ရာစာအုပ်များ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "ရေတပ်ဆိုင်ရာစာအုပ်များ"
                                : "လေတပ်ဆိုင်ရာစာအုပ်များ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "တပ်ထိန်းတပ်ဖွဲ့လက်ဆွဲစာဆောင်များ"
                                : "အထူးတပ်ဖွဲ့လက်ဆွဲစာဆောင်များ",
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
                            icon: index == 0 ? icbook : icbook,
                            title: index == 0
                                ? "လေကြောင်းရန်ကာကွယ်ရေးဆိုင်ရာစာအုပ်များ"
                                : "စစ်သတင်းများ",
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
      // bottomSheet: _text.isNotEmpty
      //     ? Container(
      //         color: Colors.black54,
      //         padding: EdgeInsets.all(16),
      //         child: Text(
      //           _text,
      //           style: TextStyle(color: Colors.white, fontSize: 18),
      //         ),
      //       )
      //     : null,
    );
  }
}
