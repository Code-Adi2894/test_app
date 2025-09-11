import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:test_app/services/speed_testing_service.dart';

import '../objectbox.dart';
import '../objectbox.g.dart';


class SyncClientManager {
  static SyncClientManager? _instance;
  late final ObjectBox objectbox;

  SyncClient? _syncClient;

  bool isStarted = false;
  bool isAutoSynOn = true;

  // Private constructor
  SyncClientManager._internal(this.objectbox);

  // One-time initializer
  static SyncClientManager? init(ObjectBox objectbox) {
    if (_instance == null) {
      _instance = SyncClientManager._internal(objectbox);
      debugPrint("✅ SyncClientManager initialized.");
    }
    return _instance;
  }

  // create sync client with neccessary parameters
  Future<void> initialize(toggleStatus) async {

    debugPrint("✅ Reusing existing ObjectBox store.");
      stop();

    var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    var ec2ServerIp = "52.1.186.253";
    _syncClient = Sync.client(
      objectbox.store,
      // 'ws://$syncServerIp:9999',
      'ws://$ec2ServerIp:9999',
      SyncCredentials.none(),
    );

    _syncClient?.setRequestUpdatesMode(toggleStatus ? SyncRequestUpdatesMode.auto : SyncRequestUpdatesMode.manual);
    print("Sync client started with request update mode: $SyncRequestUpdatesMode");

    try {
      // requestUpdates();
      _syncClient!.start();
      isStarted = true;
      debugPrint("🔄 SyncClient started with ${toggleStatus ? 'Auto' : 'Manual'}");
      if(toggleStatus){
        requestUpdates();
      }
    } catch (e) {
      debugPrint("❌ Failed to start SyncClient: $e");
    }
  }

  static SyncClientManager? get instance{
    return _instance;
  }

  /// Request updates manually via SyncUpdateService
  void requestUpdates() async{
    if (_syncClient != null) {
      // _syncClient!.requestUpdates(subscribeForFuturePushes: true);
      Duration downloadSpeed = await SpeedTestingService().testDownloadSpeed(_syncClient!);
      print("Download speed: ${downloadSpeed.inMilliseconds} ms");
    } else {
      debugPrint("⚠️ SyncClient not running, cannot request updates.");
    }
  }

  void updateApp(status){
    print("App sync: $status");
    // sync all app dataset
    initialize(status);
  }

  /// Stop the sync client
  void stop() {
    try {
      if (_syncClient != null) {
        _syncClient!.close();
        debugPrint('🛑 SyncClient stopped.');
      }
      isStarted = false;
    } catch (e) {
      debugPrint('⚠️ Error stopping SyncClient: $e');
    }
  }
}


