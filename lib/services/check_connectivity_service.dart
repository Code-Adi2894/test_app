import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:test_app/widgets/change_notifier.dart';

class CheckConnectivityService{
  // get the connection status
  // send the status to change_notifier
  // var appStore = AppStore();
  // appStore.updateConnection();
  static final CheckConnectivityService _instance = CheckConnectivityService._internal();
  factory CheckConnectivityService() => _instance;

  CheckConnectivityService._internal();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void listenToConnectivity(AppStore appStore){
    _subscription?.cancel(); // Clean previous subscription if any
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      print("Connectivity status changed: $result");

      if (result.contains(ConnectivityResult.wifi) || result.contains(ConnectivityResult.mobile)) {
        appStore.updateConnection(true);
        print("Wifi connected");
      } else {
        appStore.updateConnection(false);
        print("Wifi disconnected");
      }
    });
  }
}