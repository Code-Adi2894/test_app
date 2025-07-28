// get pending task
// export them as json
// store in the device
// after storing launch notification

import 'package:objectbox/objectbox.dart';
import 'package:test_app/services/sync_service.dart';

import '../entities.dart';
import '../main.dart';

class ExportService {
  // get task box
  final taskBox = objectbox.store.box<Task>();
  // get case box
  final caseBox = objectbox.store.box<Cases>();
  final unsyncedTasks = SyncService().getPendingTasks();
  final unsyncedCases = SyncService().getPendingCases();

  void listUnsyncedTasks(){
    final tasks = taskBox.getAll();
    print("listing");
    for(Task task in tasks){
      print('Title: ${task.title}, description: ${task.description}, isSynced: ${task.isSynced}');
    }
  }

}