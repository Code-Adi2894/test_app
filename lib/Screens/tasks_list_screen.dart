import 'package:flutter/material.dart';
import 'package:test_app/Screens/add_task_detail_dialog.dart';
import '../Screens/tasks_detail_screen.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      setState(() {
        _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void openAddTaskDialog(BuildContext context) async {
    TextEditingController taskTitlecontroller = TextEditingController();
    TextEditingController taskDescriptioncontroller = TextEditingController();
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFDC3545);
      case 'MEDIUM':
        return const Color(0xFFFFC107);
      case 'LOW':
        return const Color(0xFF28A745);
      default:
        return const Color(0xFF6C757D);
    }
  }

  @override
  Widget build(BuildContext context) {
    late Task selectedTask;
    return Scaffold(
        appBar: AppBar(
          title: Text("Tasks list for ${widget.case_.name}"),
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
        ),
        body: Column(
            children: [
              Expanded(
                  child: StreamBuilder<List<Task>>(
                  stream: getTasksForCase(widget.case_.id),
                  builder: (context, snapshot){
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_alt,
                              size: 64,
                              color: Color(0xFF6C757D),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tasks found.',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6C757D),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first task to get started!',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final tasks = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(20),
                            onTap: () {
                              selectedTask = task;
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder:
                                  (context) => TaskDetailScreen(task: selectedTask)
                                )
                              );
                            },
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF495057),
                                        ),
                                      ),
                                    ),
                                    // Sync status indicator
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (_isOnline && task.isSynced)
                                          ? const Color(0xFFE8F5E8) 
                                          : const Color(0xFFFFEBEE),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            (_isOnline && task.isSynced) ? Icons.check_circle : Icons.sync,
                                            size: 14,
                                            color: (_isOnline && task.isSynced)
                                              ? const Color(0xFF28A745) 
                                              : const Color(0xFFDC3545),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (_isOnline && task.isSynced) ? 'Synced' : 'Pending',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: (_isOnline && task.isSynced)
                                                ? const Color(0xFF28A745) 
                                                : const Color(0xFFDC3545),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  task.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6C757D),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    // Priority badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(task.priority).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        task.priority,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _getPriorityColor(task.priority),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Completion status with text and icon
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: task.isCompleted 
                                          ? const Color(0xFFE8F5E8) 
                                          : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                                            size: 14,
                                            color: task.isCompleted 
                                              ? const Color(0xFF28A745) 
                                              : const Color(0xFF6C757D),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            task.isCompleted ? 'Completed' : 'Pending',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: task.isCompleted 
                                                ? const Color(0xFF28A745) 
                                                : const Color(0xFF6C757D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    // Last updated info
                                    Text(
                                      'Updated: ${task.updatedAt.toString().substring(0, 16)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF9E9E9E),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }
              )),
              Container(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: () => showCustomDialog(context, widget.case_),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text("Add Task"),
                    ],
                  ),
                ),
              ),
            ]
        )
    );
  }
}



