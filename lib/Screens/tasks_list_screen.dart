import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';

final taskBox = objectbox.store.box<Task>();

Stream<List<Task>> getTasksForProject(int projectId){
  final query = taskBox.query(Task_.project.equals(projectId)).watch(triggerImmediately: true);
  return query.map((query) => query.find());
}

class TasksListScreen extends StatefulWidget {

  final Project project;
  const TasksListScreen({super.key, required this.project});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {

  void openAddTaskDialog(BuildContext context) async {
    TextEditingController taskTitlecontroller = TextEditingController();
    TextEditingController taskDescriptioncontroller = TextEditingController();
    bool isCompleted = false;

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("New task for ${widget.project.name}"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(hintText: 'Add task title'),
                      controller: taskTitlecontroller,
                    ),
                    TextField(
                      decoration: const InputDecoration(hintText: 'Add task description'),
                      controller: taskDescriptioncontroller
                    ),
                    Row(
                      children: [
                        Checkbox(value: isCompleted, onChanged: null),
                        const Text("Completed")
                      ],
                    )
                  ]
                )
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    String taskTitle = taskTitlecontroller.text;
                    String taskDescription = taskDescriptioncontroller.text;
                    final task = Task(
                        title: taskTitle,
                        description: taskDescription,
                        isCompleted: isCompleted,
                    );
                    try{
                      task.project.target = widget.project;
                      taskBox.put(task);
                      print('Saved input: $taskTitle, $taskDescription, $isCompleted');
                    }catch(e) {
                      print("Error $e");
                    }
                    Navigator.of(context).pop();
                  },
                  child: Text('SAVE'),
                ),

              ]
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Tasks list for ${widget.project.name}")),
        body: Column(
            children: [
              Expanded(child: StreamBuilder<List<Task>>(
                  stream: getTasksForProject(widget.project.id),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No tasks found.'));
                    }
                    final tasks = snapshot.data!;
                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(tasks[index].title),
                      ),
                    );
                  }
              )),
              ElevatedButton(
                  onPressed: () => openAddTaskDialog(context),
                  child: Text("Add task")
              )
            ]
        )
    );
  }
}


