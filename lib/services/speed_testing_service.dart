import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_app/main.dart';
import 'package:test_app/services/deserialization_service.dart';

import '../entities.dart';
import '../objectbox.g.dart';

class SpeedTestingService{
  void testUploadSpeed() async{
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/massive_dataset_20sites.json');

    if (!await file.exists()) {
      debugPrint('❌ No massive_dataset.json found.');
      return;
    }
    final stopwatch = Stopwatch()..start();
    try {
      final jsonString = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      // Boxes
      final siteBox = objectbox.store.box<Site>();

      // Deserialize and put Reports
      final sites = (jsonMap['sites'] as List<dynamic>?)
          ?.map((e) => DeserializationService().siteFromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      siteBox.putMany(sites);

      stopwatch.stop();

      debugPrint('✅ All entities uploaded and synced to ObjectBox.');
      debugPrint('⏱️ Upload duration: ${stopwatch.elapsedMilliseconds} ms');
    } catch (e, stack) {
      debugPrint('❌ Upload failed: $e');
      debugPrint(stack.toString());
    }
  }

  Future<Duration> testDownloadSpeed(SyncClient syncClient) async{
    final stopwatch = Stopwatch()..start();
    final completer = Completer<void>();

    // listen for sync completion
    final subscription = syncClient.completionEvents.listen(
        (event){
          stopwatch.stop();
          print("Sync completed in ${stopwatch.elapsedMilliseconds} ms");
          if(!completer.isCompleted) completer.complete();
        },
      onError: (error) {
        stopwatch.stop();
        print('❌ Sync error after ${stopwatch.elapsedMilliseconds} ms: $error');
        if (!completer.isCompleted) completer.completeError(error);
      },
    );

    try {
      // Trigger sync
      syncClient.requestUpdates(subscribeForFuturePushes: true);
      // Wait for completion event
      await completer.future;
      return stopwatch.elapsed;
    } finally {
      // Clean up listener
      await subscription.cancel();
    }
  }
}

