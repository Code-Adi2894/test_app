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
  String syncStatus; // 'pending', 'syncing', 'synced', 'failed'

  final cases = ToOne<Cases>();

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
    this.syncStatus = 'pending',
  }) : updatedAt = updatedAt ?? DateTime.now();
}

@Entity()
@Sync()
class TaskImage {
  int id = 0;

  @Property(type: PropertyType.byteVector)
  List<int> imageBytes;

  final task = ToOne<Task>();

  TaskImage({required this.imageBytes});
}
