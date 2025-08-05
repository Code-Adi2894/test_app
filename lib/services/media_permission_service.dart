import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

class MediaPermissionService {
  Future<bool> ensureMediaAccess() async {
    if (Platform.isAndroid) {
      final storage = await Permission.manageExternalStorage.request();

      // return images.isGranted && videos.isGranted && audio.isGranted && storage.isGranted;
      return storage.isGranted;
    } else {
      final storage = await Permission.storage.request();
      return storage.isGranted;
    }
  }
}
