// lib/services/conflict_resolution_service.dart

import '../entities.dart';

class ConflictResolutionService {
  /// Merges two Task objects, field by field.
  /// Uses `updatedAt` to decide which side “wins” on each field.
  Task mergeTasks(Task local, Task remote) {
    // Make a copy so we don’t clobber either input
    final merged = Task(
      dbId: local.dbId,
      id: local.id,
      caseId: local.caseId,
      siteId: local.siteId,
      isLiveSyncEnabled: local.isLiveSyncEnabled,
      title: local.updatedAt.isAfter(remote.updatedAt) ? local.title : remote.title,
      description: local.updatedAt.isAfter(remote.updatedAt) ? local.description : remote.description,
      isCompleted: local.updatedAt.isAfter(remote.updatedAt) ? local.isCompleted : remote.isCompleted,
      priority: local.updatedAt.isAfter(remote.updatedAt) ? local.priority : remote.priority,
      reviewNotes: local.updatedAt.isAfter(remote.updatedAt) ? local.reviewNotes : remote.reviewNotes,
      updatedAt: local.updatedAt.isAfter(remote.updatedAt) ? local.updatedAt : remote.updatedAt,
      updatedBy: local.updatedAt.isAfter(remote.updatedAt) ? local.updatedBy : remote.updatedBy,
      createdBy: remote.createdBy,
      images: remote.images
    );

    // Preserve the relationship pointers
    merged.cases.target = local.cases.target;
    // Copy over images (you might want a more robust merge here)
    merged.images.addAll(local.images);

    // Mark as synced if you’ve resolved everything
    merged.isSynced = true;

    return merged;
  }
}

// global singleton
final conflictResolutionService = ConflictResolutionService();
