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
  String priority;


  @Backlink('task')
  final images = ToMany<TaskImage>();

  final project = ToOne<Project>();

  Task({
    this.id = 0,
    required this.title,
    required this.description,
    this.isCompleted = false,
    this.priority = "LOW",
  });
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
