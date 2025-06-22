import 'package:objectbox/objectbox.dart';

@Entity()
@Sync()
class Project {
  int id;
  String name;

  @Backlink()
  final tasks = ToMany<Task>();

  Project({
    this.id = 0,
    required this.name
  });
}

@Entity()
@Sync()
class Task {
  int id;
  String title;
  String description;
  bool isCompleted;

  final project = ToOne<Project>();

  Task({
    this.id = 0,
    required this.title,
    required this.description,
    this.isCompleted = false
  });
}