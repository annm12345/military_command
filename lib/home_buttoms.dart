
import 'package:flutter/widgets.dart';
import 'package:militarycommand/styles.dart';
import 'package:velocity_x/velocity_x.dart';
import 'colors.dart';
Widget HomeButtom({width,height,icon,String? title,onPress}){
  return   Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
        Image.asset(icon,width: 40,),
        5.heightBox,
        title!.text.fontFamily(bold).color(darkFontGrey).make(),
      ],
  
  ).box.rounded.shadowMd.white.size(width, height).make();
}