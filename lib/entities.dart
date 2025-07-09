import 'package:objectbox/objectbox.dart';

@Entity()
@Sync()
class User {
  int id;
  String email;
  String password;

  User({
    this.id = 0,
    required this.email,
    required this.password,
  });
}

@Entity()
@Sync()
class Cases {
  int id;
  String name;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  DateTime? lastSyncedAt;
  String syncStatus; // 'pending', 'syncing', 'synced', 'failed'

  final site = ToOne<Site>();
  @Backlink()
  final tasks = ToMany<Task>();

  Cases({
    this.id = 0,
    required this.name,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isSynced = false,
    this.lastSyncedAt,
    this.syncStatus = 'pending',
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

@Entity()
@Sync()
class Task {
  int id;
  String title;
  String description;
  bool isCompleted;
  bool isSynced;
  String priority;
  String reviewNotes;
  DateTime updatedAt;
  String updatedBy;
  
  // Field-level change tracking for conflict resolution
  DateTime? titleLastModified;
  DateTime? descriptionLastModified;
  DateTime? isCompletedLastModified;
  DateTime? priorityLastModified;
  DateTime? reviewNotesLastModified;
  String? titleModifiedBy;
  String? descriptionModifiedBy;
  String? isCompletedModifiedBy;
  String? priorityModifiedBy;
  String? reviewNotesModifiedBy;

  final cases = ToOne<Cases>();
  @Backlink()
  final images = ToMany<TaskImage>();

  Task({
    this.id = 0,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isSynced = false,
    this.priority = "LOW",
    this.reviewNotes = '',
    DateTime? updatedAt,
    this.updatedBy = '',
    this.titleLastModified,
    this.descriptionLastModified,
    this.isCompletedLastModified,
    this.priorityLastModified,
    this.reviewNotesLastModified,
    this.titleModifiedBy,
    this.descriptionModifiedBy,
    this.isCompletedModifiedBy,
    this.priorityModifiedBy,
    this.reviewNotesModifiedBy,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

@Entity()
@Sync()
class TaskImage {
  int id;

  @Property(type: PropertyType.byteVector)
  List<int> imageBytes;
  DateTime createdAt;
  
  final task = ToOne<Task>();

  TaskImage({
    this.id = 0,
    required this.imageBytes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

@Entity()
@Sync()
class Site {
  int id;
  String name;
  String? address;
  String? description;
  DateTime createdAt;
  DateTime updatedAt;

  @Backlink()
  final cases = ToMany<Cases>();

  Site({
    this.id = 0,
    required this.name,
    this.address,
    this.description,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}