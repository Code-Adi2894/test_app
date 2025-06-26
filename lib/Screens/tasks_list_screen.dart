import 'package:flutter/material.dart';
import 'package:test_app/Screens/add_task_detail_dialog.dart';
import '../Screens/tasks_detail_screen.dart';
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
  bool isCompleted = false;

  void openAddTaskDialog(BuildContext context) async {
    TextEditingController taskTitlecontroller = TextEditingController();
    TextEditingController taskDescriptioncontroller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    late Task selectedTask;
    return Scaffold(
        appBar: AppBar(title: Text("Tasks list for ${widget.project.name}")),
        body: Column(
            children: [
              Expanded(
                  child: StreamBuilder<List<Task>>(
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
                        onTap: (){
                          selectedTask = tasks[index];
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder:
                              (context) => TaskDetailScreen(task: selectedTask)
                            )
                          );
                        }
                      ),
                    );
                  }
              )),
              ElevatedButton(
                  onPressed: () => showCustomDialog(context, widget.project),
                  child: Text("Add task")
              )
            ]
        )
    );
  }
}



