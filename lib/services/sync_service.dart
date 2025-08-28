
import '../entities.dart';
import '../main.dart';
import '../objectbox.g.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final taskBox = objectbox.store.box<Task>();
  final casesBox = objectbox.store.box<Cases>();
  final Connectivity _connectivity = Connectivity();

  // Check if device is online
  Future<bool> isOnline() async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // Get all tasks that need syncing
  List<Task> getPendingTasks() {
    final query = taskBox.query(Task_.isSynced.equals(false)).build();
    final tasks = query.find();
    query.close();
    return tasks;
  }

  // Get all cases that need syncing
  List<Cases> getPendingCases() {
    final query = casesBox.query(Cases_.isSynced.equals(false)).build();
    final cases = query.find();
    query.close();
    return cases;
  }



  // Mark task as synced
  void markTaskAsSynced(Task task) {
    task.isSynced = true;
    task.updatedAt = DateTime.now();
    taskBox.put(task);
  }

  // Mark case as synced
  void markCaseAsSynced(Cases case_) {
    case_.isSynced = true;
    case_.updatedAt = DateTime.now();
    // case_.lastSyncedAt = DateTime.now();
    case_.isSynced = true;
    casesBox.put(case_);
  }



  // Get sync statistics
  Map<String, int> getSyncStats() {
    final pendingTasks = getPendingTasks().length;
    final pendingCases = getPendingCases().length;
    final totalTasks = taskBox.count();
    final totalCases = casesBox.count();

    return {
      'pendingTasks': pendingTasks,
      'pendingCases': pendingCases,
      'totalTasks': totalTasks,
      'totalCases': totalCases,
      'syncedTasks': totalTasks - pendingTasks,
      'syncedCases': totalCases - pendingCases,
    };
  }

  // Check if there are any pending syncs
  bool hasPendingSyncs() {
    return getPendingTasks().isNotEmpty || getPendingCases().isNotEmpty;
  }

  // Get sync status message
  String getSyncStatusMessage() {
    final stats = getSyncStats();
    final pendingTasks = stats['pendingTasks'] ?? 0;
    final pendingCases = stats['pendingCases'] ?? 0;

    if (pendingTasks == 0 && pendingCases == 0) {
      return 'All data is synced';
    } else {
      final parts = <String>[];
      if (pendingCases > 0) parts.add('$pendingCases cases');
      if (pendingTasks > 0) parts.add('$pendingTasks tasks');
      return '${parts.join(', ')} pending sync';
    }
  }

  // Perform actual sync operation with server
  Future<bool> performSync() async {
    if (!await isOnline()) {
      throw Exception('No internet connection available');
    }

    try {
      final pendingTasks = getPendingTasks();
      final pendingCases = getPendingCases();

      if (pendingTasks.isEmpty && pendingCases.isEmpty) {
        return true; // Nothing to sync
      }

      // Simulate actual server sync (replace with real API calls)
      await Future.delayed(const Duration(seconds: 2));

      final syncTime = DateTime.now();
      for (var task in pendingTasks) {
        task.isSynced = true;
        task.updatedAt = syncTime;
        taskBox.put(task);
      }
      for (var case_ in pendingCases) {
        case_.isSynced = true;
        // case_.lastSyncedAt = syncTime;
        case_.isSynced = true;
        case_.updatedAt = syncTime;
        casesBox.put(case_);
      }

      return true;
    } catch (e) {
      print('Sync failed: $e');
      return false;
    }
  }

  // Sync specific case
  Future<bool> syncCase(Cases case_) async {
    if (!await isOnline()) {
      throw Exception('No internet connection available');
    }

    try {
      await Future.delayed(const Duration(seconds: 1));
      final syncTime = DateTime.now();

      case_.isSynced = true;
      // case_.lastSyncedAt = syncTime;
      case_.isSynced = true;
      case_.updatedAt = syncTime;

      // Sync all tasks in this case
      final tasks = taskBox.query(Task_.cases.equals(case_.dbId)).build().find();
      for (var task in tasks) {
        task.isSynced = true;
        task.updatedAt = syncTime;
      }
      taskBox.putMany(tasks);

      casesBox.put(case_);
      return true;
    } catch (e) {
      print('Case sync failed: $e');
      return false;
    }
  }

  Future<bool> syncPendingTask() async{
      try{
        var unsyncedTasks = getPendingTasks();
        for (Task task in unsyncedTasks){
          task.isSynced = true;
          taskBox.put(task);
        }
        return true;
      }catch(err){
        print('Task sync failed: $err');
        return false;
      }
  }

  // Sync specific task
  Future<bool> syncTask(Task task) async {
    if (!await isOnline()) {
      throw Exception('No internet connection available');
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final syncTime = DateTime.now();
      task.isSynced = true;
      task.updatedAt = syncTime;
      taskBox.put(task);
      return true;
    } catch (e) {
      print('Task sync failed: $e');
      return false;
    }
  }



  // Get sync options for UI
  List<Map<String, dynamic>> getSyncOptions() {
    final stats = getSyncStats();
    final pendingTasks = stats['pendingTasks'] ?? 0;
    final pendingCases = stats['pendingCases'] ?? 0;
    final pendingSites = stats['pendingSites'] ?? 0;

    return [
      // {
      //   'title': 'Sync All Data',
      //   'subtitle': 'Sync all pending cases and tasks',
      //   'icon': Icons.sync,
      //   'enabled': pendingTasks > 0 || pendingCases > 0,
      // },
      // {
      //   'title': 'Sync Cases Only',
      //   'subtitle': 'Sync only pending cases',
      //   'icon': Icons.folder_open,
      //   'enabled': pendingCases > 0,
      // },
      // {
      //   'title': 'Sync Tasks Only',
      //   'subtitle': 'Sync only pending tasks',
      //   'icon': Icons.task_alt,
      //   'enabled': pendingTasks > 0,
      // },
      {
        'title': 'View Sync Status',
        'subtitle': 'Check current sync statistics',
        'icon': Icons.info_outline,
        'enabled': true,
      },
    ];
  }
}

// Global instance
final syncService = SyncService();
