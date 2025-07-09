import 'package:connectivity_plus/connectivity_plus.dart';
import '../entities.dart';
import '../main.dart';
import '../objectbox.g.dart';
import 'conflict_resolution_service.dart';
import 'user_service.dart';

class ConflictDetectionService {
  static final ConflictDetectionService _instance = ConflictDetectionService._internal();
  factory ConflictDetectionService() => _instance;
  ConflictDetectionService._internal();

  final taskBox = objectbox.store.box<Task>();
  final Connectivity _connectivity = Connectivity();

  /// Checks for conflicts when coming back online
  Future<List<Task>> checkForConflicts() async {
    final pendingTasks = taskBox.query(Task_.isSynced.equals(false)).build().find();
    final tasksWithConflicts = <Task>[];

    for (final task in pendingTasks) {
      // Get the current version from the database (which might have been updated by sync)
      final currentTask = taskBox.get(task.id);
      if (currentTask != null && currentTask != task) {
        // Check if there are actual field-level conflicts
        if (conflictResolutionService.hasConflicts(task, currentTask)) {
          tasksWithConflicts.add(task);
        }
      }
    }

    return tasksWithConflicts;
  }

  /// Detects conflicts when a user opens a task detail screen
  Future<TaskConflictData?> detectConflictsForTask(Task localTask) async {
    // Get the current version from the database
    final currentTask = taskBox.get(localTask.id);
    
    if (currentTask == null || currentTask == localTask) {
      return null; // No conflicts
    }

    // Check if there are actual conflicts
    if (conflictResolutionService.hasConflicts(localTask, currentTask)) {
      return conflictResolutionService.detectConflicts(localTask, currentTask);
    }

    return null;
  }

  /// Monitors connectivity changes and checks for conflicts when coming back online
  void startConflictMonitoring() {
    _connectivity.onConnectivityChanged.listen((results) async {
      final isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
      
      if (isOnline) {
        // Check for conflicts when coming back online
        final conflicts = await checkForConflicts();
        if (conflicts.isNotEmpty) {
          print('Found ${conflicts.length} tasks with conflicts');
          // You can show a notification here or store the conflicts for later
          _storePendingConflicts(conflicts);
        }
      }
    });
  }

  /// Store conflicts that need to be resolved
  void _storePendingConflicts(List<Task> conflicts) {
    // You can implement a simple storage mechanism here
    // For now, we'll use a global variable
    _pendingConflicts.addAll(conflicts);
  }

  /// Get pending conflicts
  List<Task> getPendingConflicts() {
    return List.from(_pendingConflicts);
  }

  /// Remove a resolved conflict
  void removeResolvedConflict(Task task) {
    _pendingConflicts.removeWhere((t) => t.id == task.id);
  }

  // Global list to store pending conflicts
  final List<Task> _pendingConflicts = [];
}

// Global instance
final conflictDetectionService = ConflictDetectionService(); 