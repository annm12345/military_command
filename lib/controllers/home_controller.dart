import 'package:get/get.dart';

class HomeController extends GetxController{
  var currentHavIndex=0.obs;

  void updateIndex(int index) {
    currentHavIndex.value = index;
  }
}