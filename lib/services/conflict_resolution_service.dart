// lib/services/conflict_resolution_service.dart

import '../entities.dart';
import '../main.dart';
import '../objectbox.g.dart';
import 'user_service.dart'; // Add this import

class TaskFieldChange {
  final String fieldName;
  final String localValue;
  final String remoteValue;
  final DateTime localModifiedAt;
  final DateTime remoteModifiedAt;
  final String localModifiedBy;
  final String remoteModifiedBy;
  final bool hasConflict;

  TaskFieldChange({
    required this.fieldName,
    required this.localValue,
    required this.remoteValue,
    required this.localModifiedAt,
    required this.remoteModifiedAt,
    required this.localModifiedBy,
    required this.remoteModifiedBy,
    required this.hasConflict,
  });
}

class TaskConflictData {
  final Task localTask;
  final Task remoteTask;
  final List<TaskFieldChange> conflictingFields;
  final List<TaskFieldChange> nonConflictingFields;

  TaskConflictData({
    required this.localTask,
    required this.remoteTask,
    required this.conflictingFields,
    required this.nonConflictingFields,
  });
}

class ConflictResolutionService {
  static final ConflictResolutionService _instance = ConflictResolutionService._internal();
  factory ConflictResolutionService() => _instance;
  ConflictResolutionService._internal();

  final taskBox = objectbox.store.box<Task>();

  /// Detects conflicts between local and remote tasks at field level
  TaskConflictData detectConflicts(Task localTask, Task remoteTask) {
    final conflictingFields = <TaskFieldChange>[];
    final nonConflictingFields = <TaskFieldChange>[];

    // Check each field for conflicts
    _checkFieldConflict('title', localTask.title, remoteTask.title, 
        localTask.titleLastModified, remoteTask.titleLastModified,
        localTask.titleModifiedBy, remoteTask.titleModifiedBy,
        conflictingFields, nonConflictingFields);

    _checkFieldConflict('description', localTask.description, remoteTask.description,
        localTask.descriptionLastModified, remoteTask.descriptionLastModified,
        localTask.descriptionModifiedBy, remoteTask.descriptionModifiedBy,
        conflictingFields, nonConflictingFields);

    _checkFieldConflict('isCompleted', localTask.isCompleted.toString(), remoteTask.isCompleted.toString(),
        localTask.isCompletedLastModified, remoteTask.isCompletedLastModified,
        localTask.isCompletedModifiedBy, remoteTask.isCompletedModifiedBy,
        conflictingFields, nonConflictingFields);

    _checkFieldConflict('priority', localTask.priority, remoteTask.priority,
        localTask.priorityLastModified, remoteTask.priorityLastModified,
        localTask.priorityModifiedBy, remoteTask.priorityModifiedBy,
        conflictingFields, nonConflictingFields);

    _checkFieldConflict('reviewNotes', localTask.reviewNotes, remoteTask.reviewNotes,
        localTask.reviewNotesLastModified, remoteTask.reviewNotesLastModified,
        localTask.reviewNotesModifiedBy, remoteTask.reviewNotesModifiedBy,
        conflictingFields, nonConflictingFields);

    return TaskConflictData(
      localTask: localTask,
      remoteTask: remoteTask,
      conflictingFields: conflictingFields,
      nonConflictingFields: nonConflictingFields,
    );
  }

  void _checkFieldConflict(
    String fieldName,
    String localValue,
    String remoteValue,
    DateTime? localModifiedAt,
    DateTime? remoteModifiedAt,
    String? localModifiedBy,
    String? remoteModifiedBy,
    List<TaskFieldChange> conflictingFields,
    List<TaskFieldChange> nonConflictingFields,
  ) {
    // If both values are the same, no conflict
    if (localValue == remoteValue) {
      return;
    }

    // If one side hasn't been modified, no conflict
    if (localModifiedAt == null || remoteModifiedAt == null) {
      nonConflictingFields.add(TaskFieldChange(
        fieldName: fieldName,
        localValue: localValue,
        remoteValue: remoteValue,
        localModifiedAt: localModifiedAt ?? DateTime.now(),
        remoteModifiedAt: remoteModifiedAt ?? DateTime.now(),
        localModifiedBy: localModifiedBy ?? 'Unknown',
        remoteModifiedBy: remoteModifiedBy ?? 'Unknown',
        hasConflict: false,
      ));
      return;
    }

    // If both sides have been modified at different times, check for conflicts
    final hasConflict = localModifiedAt.isAfter(remoteModifiedAt) && 
                       remoteModifiedAt.isAfter(localModifiedAt);

    final fieldChange = TaskFieldChange(
      fieldName: fieldName,
      localValue: localValue,
      remoteValue: remoteValue,
      localModifiedAt: localModifiedAt,
      remoteModifiedAt: remoteModifiedAt,
      localModifiedBy: localModifiedBy ?? 'Unknown',
      remoteModifiedBy: remoteModifiedBy ?? 'Unknown',
      hasConflict: hasConflict,
    );

    if (hasConflict) {
      conflictingFields.add(fieldChange);
    } else {
      nonConflictingFields.add(fieldChange);
    }
  }

  /// Updates field-level tracking when a field is modified
  void updateFieldTracking(Task task, String fieldName, String value) {
    final now = DateTime.now();
    final user = userService.getCurrentUserEmail();

    switch (fieldName) {
      case 'title':
        if (task.title != value) {
          task.title = value;
          task.titleLastModified = now;
          task.titleModifiedBy = user;
        }
        break;
      case 'description':
        if (task.description != value) {
          task.description = value;
          task.descriptionLastModified = now;
          task.descriptionModifiedBy = user;
        }
        break;
      case 'isCompleted':
        final boolValue = value.toLowerCase() == 'true';
        if (task.isCompleted != boolValue) {
          task.isCompleted = boolValue;
          task.isCompletedLastModified = now;
          task.isCompletedModifiedBy = user;
        }
        break;
      case 'priority':
        if (task.priority != value) {
          task.priority = value;
          task.priorityLastModified = now;
          task.priorityModifiedBy = user;
        }
        break;
      case 'reviewNotes':
        if (task.reviewNotes != value) {
          task.reviewNotes = value;
          task.reviewNotesLastModified = now;
          task.reviewNotesModifiedBy = user;
        }
        break;
    }

    task.updatedAt = now;
    task.updatedBy = user;
    task.isSynced = false;
  }

  /// Merges tasks based on user choices for conflicting fields
  Task mergeTasks(Task localTask, Task remoteTask, Map<String, String> userChoices) {
    final merged = Task(
      id: localTask.id,
      title: userChoices['title'] == 'local' ? localTask.title : remoteTask.title,
      description: userChoices['description'] == 'local' ? localTask.description : remoteTask.description,
      isCompleted: userChoices['isCompleted'] == 'local' ? localTask.isCompleted : remoteTask.isCompleted,
      priority: userChoices['priority'] == 'local' ? localTask.priority : remoteTask.priority,
      reviewNotes: userChoices['reviewNotes'] == 'local' ? localTask.reviewNotes : remoteTask.reviewNotes,
      updatedAt: DateTime.now(),
      updatedBy: userService.getCurrentUserEmail(),
      isSynced: false,
    );

    // Update field-level tracking for merged fields
    final now = DateTime.now();
    final user = userService.getCurrentUserEmail();

    if (userChoices['title'] == 'local') {
      merged.titleLastModified = localTask.titleLastModified;
      merged.titleModifiedBy = localTask.titleModifiedBy;
    } else {
      merged.titleLastModified = remoteTask.titleLastModified;
      merged.titleModifiedBy = remoteTask.titleModifiedBy;
    }

    if (userChoices['description'] == 'local') {
      merged.descriptionLastModified = localTask.descriptionLastModified;
      merged.descriptionModifiedBy = localTask.descriptionModifiedBy;
    } else {
      merged.descriptionLastModified = remoteTask.descriptionLastModified;
      merged.descriptionModifiedBy = remoteTask.descriptionModifiedBy;
    }

    if (userChoices['isCompleted'] == 'local') {
      merged.isCompletedLastModified = localTask.isCompletedLastModified;
      merged.isCompletedModifiedBy = localTask.isCompletedModifiedBy;
    } else {
      merged.isCompletedLastModified = remoteTask.isCompletedLastModified;
      merged.isCompletedModifiedBy = remoteTask.isCompletedModifiedBy;
    }

    if (userChoices['priority'] == 'local') {
      merged.priorityLastModified = localTask.priorityLastModified;
      merged.priorityModifiedBy = localTask.priorityModifiedBy;
    } else {
      merged.priorityLastModified = remoteTask.priorityLastModified;
      merged.priorityModifiedBy = remoteTask.priorityModifiedBy;
    }

    if (userChoices['reviewNotes'] == 'local') {
      merged.reviewNotesLastModified = localTask.reviewNotesLastModified;
      merged.reviewNotesModifiedBy = localTask.reviewNotesModifiedBy;
    } else {
      merged.reviewNotesLastModified = remoteTask.reviewNotesLastModified;
      merged.reviewNotesModifiedBy = remoteTask.reviewNotesModifiedBy;
    }

    // Preserve relationships
    merged.cases.target = localTask.cases.target;
    merged.images.addAll(localTask.images);

    return merged;
  }

  String _getCurrentUserEmail() {
    // Use the actual user service to get current user
    try {
      return userService.getCurrentUserEmail();
    } catch (e) {
      return 'unknown_user';
    }
  }

  /// Checks if a task has any conflicts with the remote version
  bool hasConflicts(Task localTask, Task remoteTask) {
    print('🔍 Checking for conflicts between tasks:');
    print('Local Task ID: ${localTask.id}, Updated: ${localTask.updatedAt}');
    print('Remote Task ID: ${remoteTask.id}, Updated: ${remoteTask.updatedAt}');
    
    // If the tasks are exactly the same, no conflicts
    if (localTask.id == remoteTask.id && 
        localTask.title == remoteTask.title &&
        localTask.description == remoteTask.description &&
        localTask.isCompleted == remoteTask.isCompleted &&
        localTask.priority == remoteTask.priority &&
        localTask.reviewNotes == remoteTask.reviewNotes) {
      print('✅ No conflicts - tasks are identical');
      return false;
    }

    // Check for field-level conflicts
    final conflictData = detectConflicts(localTask, remoteTask);
    final hasConflicts = conflictData.conflictingFields.isNotEmpty;
    
    print('🔍 Found ${conflictData.conflictingFields.length} conflicting fields');
    print('🔍 Found ${conflictData.nonConflictingFields.length} non-conflicting fields');
    
    return hasConflicts;
  }

  /// Gets all tasks that might have conflicts
  List<Task> getTasksWithPotentialConflicts() {
    final query = taskBox.query(Task_.isSynced.equals(false)).build();
    final tasks = query.find();
    query.close();
    return tasks;
  }
}

// Global instance
final conflictResolutionService = ConflictResolutionService();
