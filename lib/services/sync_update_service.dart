import 'package:test_app/services/sync_client_manager.dart';


class SyncUpdateService {
  static SyncUpdateService? _instance;
  // final SyncClient syncClient;
  late final SyncClientManager syncClientManager;

  // // Private constructor
  SyncUpdateService._internal(this.syncClientManager);
  //
  // // Factory constructor to initialize once
  // factory SyncUpdateService({required SyncClient syncClient}) {
  //   return _instance ??= SyncUpdateService._internal(syncClient);
  // }

  static void init({required SyncClientManager manager}) {
    if (_instance == null) {
      print("Sync update manager initialized");
      _instance = SyncUpdateService._internal(manager);
    }
  }

  static SyncUpdateService get instance {
    if (_instance == null) {
      throw Exception('SyncUpdateService is not initialized yet.');
    }
    return _instance!;
  }

  void updateApp(status){
    print("App sync: $status");
    // sync all app datat
    syncClientManager.initialize(status);
  }

}
