import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../objectbox.dart';
import '../objectbox.g.dart';
import '../widgets/change_notifier.dart';


class SyncClientManager {
  static final SyncClientManager _instance = SyncClientManager._internal();
  factory SyncClientManager() => _instance;
  SyncClientManager._internal();

  SyncClient? _syncClient;

  bool isStarted = false;
  bool isAutoSynOn = true;

  constructor(isAutoSynOn) {
    this.isAutoSynOn = isAutoSynOn;
  }

  // create sync client with neccessary parameters
  Future<void> initialize(toggleStatus) async {
    stop();
    var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
    _syncClient = Sync.client(
      objectbox.store,
      'ws://$syncServerIp:9999',
      SyncCredentials.none(),
    );

    _syncClient?.setRequestUpdatesMode(toggleStatus ? SyncRequestUpdatesMode.auto : SyncRequestUpdatesMode.manual);
    print("Sync client started with request update mode: ${SyncRequestUpdatesMode}");

    try {
      _syncClient!.start();
      isStarted = true;
      debugPrint("🔄 SyncClient started (${toggleStatus ? 'Auto' : 'Manual'})");
    } catch (e) {
      debugPrint("❌ Failed to start SyncClient: $e");
    }
  }

  /// Request updates manually via SyncUpdateService
  // void requestUpdates() {
  //   if (_isStarted && syncService != null) {
  //     syncService!.requestUpdates();
  //   } else {
  //     debugPrint("⚠️ SyncClient not running, cannot request updates.");
  //   }
  // }


  /// Stop the sync client
  void stop() {
    try {
      if (_syncClient != null) {
        _syncClient!.close();
        debugPrint('🛑 SyncClient stopped.');
      }
      isStarted = false;
      debugPrint('🛑 SyncClient stopped.');
    } catch (e) {
      debugPrint('⚠️ Error stopping SyncClient: $e');
    }
  }
}


