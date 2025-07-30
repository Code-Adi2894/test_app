// get pending task
// export them as json
// store in the device
// after storing launch notification

import '../entities.dart';
import '../main.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../objectbox.g.dart';
import 'media_permission_service.dart';


class ExportService {
  // get task box
  final taskBox = objectbox.store.box<Task>();
  // get case box
  final caseBox = objectbox.store.box<Cases>();

  Future<void> exportUnsyncedTasks() async {
    try{
      final query = taskBox.query(Task_.isSynced.equals(false)).build();
      final tasks = query.find();
      query.close();

      if (tasks.isEmpty) {
        print('No unsynced tasks to export.');
        return;
      }

      // Convert tasks to list of maps
      final taskList = tasks.map((task) =>
      {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority,
        'reviewNotes': task.reviewNotes,
        'updatedBy': task.updatedBy,
        'updatedAt': task.updatedAt.toIso8601String(),
      }).toList();

      final jsonString = jsonEncode(taskList);

      // Request storage permission
      final permissionsGranted = await MediaPermissionService().ensureMediaAccess();
      if (!permissionsGranted) {
        print('Storage permission denied');
        return;
      }

      // Get device directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/unsynced_tasks_${DateTime
          .now()
          .millisecondsSinceEpoch}.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      print('✅ Exported ${tasks.length} unsynced tasks to $filePath');
    }catch(e) {
      print('❌ Export failed: $e');
    }
  }
}