import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test_app/Screens/add_task_detail_dialog.dart';
import '../Screens/tasks_detail_screen.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import '../widgets/change_notifier.dart';

final taskBox = objectbox.store.box<Task>();

Stream<List<Task>> getTasksForCase(int caseId){
  final query = taskBox.query(Task_.cases.equals(caseId)).watch(triggerImmediately: true);
  return query.map((query) => query.find());
}

class TasksListScreen extends StatefulWidget {

  final Cases case_;
  const TasksListScreen({super.key, required this.case_});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}


class _TasksListScreenState extends State<TasksListScreen> {
  bool isCompleted = false;
  bool _isOnline = true;
  late final Connectivity _connectivity;
  late StreamSubscription<List<ConnectivityResult>>  _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    // _connectivity = Connectivity();
    // _checkConnectivity();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      // Received changes in available connectivity types!
      setState(() {
        _isOnline = result.contains(ConnectivityResult.wifi);
        print('source (updated): $_isOnline');
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
      print('source (after check): $_isOnline');
    });
  }

  void openAddTaskDialog(BuildContext context) async {
    TextEditingController taskTitlecontroller = TextEditingController();
    TextEditingController taskDescriptioncontroller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    var connectionStatus = context.watch<AppStore>().isConnected;
    late Task selectedTask;
    return Scaffold(
        appBar: AppBar(title: Text("Tasks list for ${widget.case_.title}")),
        body: Column(
            children: [
              Expanded(
                  child: StreamBuilder<List<Task>>(
                  stream: getTasksForCase(widget.case_.dbId),
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
                              (context) => TaskDetailScreen(task: selectedTask, cases: widget.case_)
                            )
                          );
                        }
                      ),
                    );
                  }
              )),
              ElevatedButton(
                  onPressed: () => showCustomDialog(context, widget.case_, connectionStatus),
                  child: Text("Add task")
              )
            ]
        )
    );
  }
}



