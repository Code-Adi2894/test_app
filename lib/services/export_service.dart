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

  Future<List<Map<String, Object>>> getUnsyncedTasks() async {
    try{
      final query = taskBox.query(Task_.isSynced.equals(false)).build();
      final tasks = query.find();
      query.close();

      if (tasks.isEmpty) {
        return [];
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
        'isSynced':task.isSynced,
        'updatedBy': task.updatedBy,
        'updatedAt': task.updatedAt.toIso8601String(),
      }).toList();
      return taskList;
    }catch(e){
      print('❌ Export failed: $e');
      return [];
    }
  }

  Future<List<Map<String, Object?>>> getUnsyncedCases() async {
    try{
      final query = caseBox.query(Cases_.isSynced.equals(false)).build();
      final cases = query.find();
      query.close();

      if (cases.isEmpty) {
        return [];
      }

      // Convert tasks to list of maps
      final casesList = cases.map((case_) =>
      {
        'id': case_.id,
        'name': case_.name,
        'description': case_.description,
        'isSynced':case_.isSynced,
        'createdAt': case_.createdAt.toIso8601String(),
        'lastSynced': case_.lastSyncedAt?.toIso8601String(),
        'updatedAt': case_.updatedAt.toIso8601String(),
      }).toList();
      return casesList;
    }catch(e){
      print('❌ Export failed: $e');
      return [];
    }
  }


  Future<void> exportUnsyncedData() async{
    try {
      var unsyncedCases = await getUnsyncedCases();
      var unsyncedTasks = await getUnsyncedTasks();

      var dataList = [...unsyncedCases, ...unsyncedTasks];

      if(dataList.isEmpty){
        print("No unsynced data");
        return;
      }

      // Request storage permission
      final permissionsGranted = await MediaPermissionService()
          .ensureMediaAccess();
      if (!permissionsGranted) {
        print('Storage permission denied');
        return;
      }

      final jsonString = jsonEncode(dataList);

      // Get device directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/unsynced_tasks_${DateTime
          .now()
          .millisecondsSinceEpoch}.json';
      final file = File(filePath);
      await file.writeAsString(jsonString);
      print('✅ Exported ${dataList.length} unsynced data to $filePath');
    }catch(e){
      print('❌ Export failed: $e');
    }
  }
}