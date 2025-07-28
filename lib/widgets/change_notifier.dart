import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

class AppStore extends ChangeNotifier {
  bool isConnected = true;

  void updateConnection(bool status){
    isConnected = status;
    notifyListeners();
  }
}