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
  @Id()
  int dbId;

  @Index()
  String id;

  String title;
  String? description;
  String status; // open, closed, resolved, on hold, in progress
  DateTime createdAt;
  DateTime updatedAt;
  bool isSynced;
  String createdBy;
  String updatedBy;
  String? siteId;
  bool isLiveSyncEnabled;

  final site = ToOne<Site>();
  @Backlink()
  final tasks = ToMany<Task>();

  Cases({
    this.dbId = 0,
    required this.id,
    required this.title,
    this.description,
    required this.status,
    DateTime? createdAt,
    DateTime? updatedAt,
    required this.createdBy,
    required this.updatedBy,
    this.siteId = '',
    required this.isLiveSyncEnabled,
    this.isSynced = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}

@Entity()
@Sync()
class Task {
  @Id()
  int dbId;

  @Index()
  String id;

  String title;
  String description;
  bool isCompleted;
  bool isSynced;
  String priority;
  String reviewNotes;
  DateTime updatedAt;
  String updatedBy;
  String createdBy;
  DateTime createdAt;
  bool isLiveSyncEnabled;
  String caseId;
  String siteId;
  List<String> images;

  final cases = ToOne<Cases>();
  @Backlink()
  final taskImages = ToMany<TaskImage>();

  Task({
    this.dbId = 0,
    required this.id,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.isSynced = false,
    this.priority = "LOW",
    this.reviewNotes = '',
    required this.createdBy,
    required this.updatedBy,
    required this.isLiveSyncEnabled,
    required this.caseId,
    required this.siteId,
    required this.images,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();
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
  @Id()
  int dbId;

  @Index()
  String id;

  String name;
  String? address;
  String? description; // not in json
  DateTime createdAt;
  DateTime updatedAt;
  String? createdBy;
  String? updatedBy;
  bool isSynced;

  @Backlink()
  final cases = ToMany<Cases>();

  Site({
    this.dbId = 0,
    required this.id,
    required this.name,
    this.address,
    this.description,
    this.createdBy,
    this.updatedBy,
    required this.isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();
}