import 'package:flutter/cupertino.dart';

class AppStore extends ChangeNotifier {
  bool isConnected = true;

  void updateConnection(bool status){
    isConnected = status;
    notifyListeners();
  }
}