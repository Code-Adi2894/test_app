import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../objectbox.g.dart';
import '../entities.dart';
import '../main.dart';
import '../services/user_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import '../widgets/change_notifier.dart';

final taskBox = objectbox.store.box<Task>();
final taskImageBox = objectbox.store.box<TaskImage>();

// Stream to watch for changes to a specific task
Stream<Task?> getTaskStream(int taskId) {
  return taskBox.query(Task_.dbId.equals(taskId)).watch(triggerImmediately: true).map((query) {
    final tasks = query.find();
    return tasks.isNotEmpty ? tasks.first : null;
  });
}

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final Cases cases;
  const TaskDetailScreen({super.key, required this.task, required this.cases});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController reviewNotesController;
  bool isCompleted = false;
  String priority = '';
  var levels = ["LOW", "MEDIUM", "HIGH"];
  bool _isOnline = true;
  bool _isSyncing = false;
  late final Connectivity _connectivity;
  File? imageFile;

  @override
  void initState(){
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    reviewNotesController = TextEditingController(text: widget.task.reviewNotes);
    isCompleted = widget.task.isCompleted;
    priority = widget.task.priority;
    
    // Initialize connectivity
    _connectivity = Connectivity();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose(){
    titleController.dispose();
    descriptionController.dispose();
    reviewNotesController.dispose();
    super.dispose();
  }

  void _saveChanges(connectionStatus) {
    // Log the task before saving
    print('\n💾 SAVE OPERATION STARTED');
    _logTaskProperties('TASK BEFORE SAVE', widget.task);
    
    widget.task.title = titleController.text;
    widget.task.description = descriptionController.text;
    widget.task.reviewNotes = reviewNotesController.text;
    widget.task.isCompleted = isCompleted;
    widget.task.priority = priority;
    widget.task.updatedAt = DateTime.now();
    widget.task.updatedBy = userService.getCurrentUserEmail();
    widget.task.isSynced = false;

    try{
      widget.task.cases.target = widget.cases;
      taskBox.put(widget.task);
      
      // Log the task after saving
      print('\n✅ SAVE OPERATION COMPLETED');
      _logTaskProperties('TASK AFTER SAVE', widget.task);
      
      // Auto-sync if online
      if (connectionStatus) {
        _syncTask();
      }
      
      Navigator.pop(context);
      print("Updated task");
    }catch(e){
      print("Error $e");
    }
  }

  void _syncTask() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // Log the task before syncing
      print('\n🔄 SYNC OPERATION STARTED');
      _logTaskProperties('TASK TO SYNC', widget.task);
      
      final success = await syncService.syncTask(widget.task);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task synced successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Sync operation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  // Helper method to get current task from database
  Task getCurrentTask() {
    final query = taskBox.query(Task_.id.equals(widget.task.id)).build();
    final tasks = query.find();
    query.close();
    return tasks.isNotEmpty ? tasks.first : widget.task;
  }

  // Helper method to check for conflicts
  bool _hasConflicts(Task local, Task remote) {
    // Implementation of _hasConflicts method
    return false; // Placeholder return, actual implementation needed
  }

  // Helper method to log task properties
  void _logTaskProperties(String taskName, Task task) {
    print('=== $taskName Task Properties ===');
    print('ID: ${task.id}');
    print('Title: "${task.title}"');
    print('Description: "${task.description}"');
    print('Is Completed: ${task.isCompleted}');
    print('Is Synced: ${task.isSynced}');
    print('Priority: "${task.priority}"');
    print('Review Notes: "${task.reviewNotes}"');
    print('Updated At: ${task.updatedAt}');
    print('Updated By: "${task.updatedBy}"');
    print('Cases ID: ${task.cases.target?.id ?? "null"}');
    print('Images Count: ${task.images.length}');
    print('================================');
  }

  // Helper method to compare and log two tasks
  void _logTaskComparison(Task localTask, Task remoteTask) {
    print('\n🔍 TASK COMPARISON LOG 🔍');
    print('=' * 50);
    
    _logTaskProperties('LOCAL', localTask);
    print('');
    _logTaskProperties('REMOTE', remoteTask);
    print('');
    
    // Log differences
    print('📊 DIFFERENCES:');
    if (localTask.title != remoteTask.title) {
      print('❌ Title: Local="${localTask.title}" vs Remote="${remoteTask.title}"');
    }
    if (localTask.description != remoteTask.description) {
      print('❌ Description: Local="${localTask.description}" vs Remote="${remoteTask.description}"');
    }
    if (localTask.isCompleted != remoteTask.isCompleted) {
      print('❌ Completed: Local=${localTask.isCompleted} vs Remote=${remoteTask.isCompleted}');
    }
    if (localTask.priority != remoteTask.priority) {
      print('❌ Priority: Local="${localTask.priority}" vs Remote="${remoteTask.priority}"');
    }
    if (localTask.reviewNotes != remoteTask.reviewNotes) {
      print('❌ Review Notes: Local="${localTask.reviewNotes}" vs Remote="${remoteTask.reviewNotes}"');
    }
    if (localTask.isSynced != remoteTask.isSynced) {
      print('❌ Synced: Local=${localTask.isSynced} vs Remote=${remoteTask.isSynced}');
    }
    if (localTask.updatedAt != remoteTask.updatedAt) {
      print('❌ Updated At: Local=${localTask.updatedAt} vs Remote=${remoteTask.updatedAt}');
    }
    if (localTask.updatedBy != remoteTask.updatedBy) {
      print('❌ Updated By: Local="${localTask.updatedBy}" vs Remote="${remoteTask.updatedBy}"');
    }
    
    print('=' * 50);
  }

  @override
  Widget build(BuildContext context) {
    var connectionStatus = context.watch<AppStore>().isConnected;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: StreamBuilder<Task?>(
          stream: getTaskStream(widget.task.dbId),
          builder: (context, snapshot) {
            final task = snapshot.data ?? widget.task;
            return Text(
              task.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        ),
        actions: [
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _syncTask,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sync Task',
            ),
          IconButton(
            onPressed: () => _saveChanges(connectionStatus),
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Changes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // const OfflineIndicator(),
          Expanded(
            child: StreamBuilder<Task?>(
              stream: getTaskStream(widget.task.dbId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Color(0xFF6C757D),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Color(0xFF6C757D)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final task = snapshot.data ?? widget.task;
                
                // Log local and remote tasks for debugging
                _logTaskProperties('LOCAL (widget.task)', widget.task);
                _logTaskProperties('REMOTE (from stream)', task);
                
                // Update controllers with latest data
                if (task.title != titleController.text) {
                  titleController.text = task.title;
                }
                if (task.description != descriptionController.text) {
                  descriptionController.text = task.description;
                }
                if (task.reviewNotes != reviewNotesController.text) {
                  reviewNotesController.text = task.reviewNotes;
                }
                if (task.isCompleted != isCompleted) {
                  isCompleted = task.isCompleted;
                }
                if (task.priority != priority) {
                  priority = task.priority;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Details Card
                      Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          task.title,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF495057),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Task Details',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: task.isSynced 
                                        ? const Color(0xFFE8F5E8) 
                                        : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          task.isSynced ? Icons.check_circle : Icons.sync,
                                          size: 14,
                                          color: task.isSynced 
                                            ? const Color(0xFF28A745) 
                                            : const Color(0xFFDC3545),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.isSynced ? 'Synced' : 'Pending',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: task.isSynced 
                                              ? const Color(0xFF28A745) 
                                              : const Color(0xFFDC3545),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                task.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: const Color(0xFF9E9E9E),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Updated: ${task.updatedAt.toString().substring(0, 19)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                              if (task.updatedBy.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'By: ${task.updatedBy}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images Section
                      if(task.images.isNotEmpty)
                        Container(
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
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.photo_library,
                                      color: Color(0xFF2196F3),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Task Images',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF495057),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: task.images.length,
                                    itemBuilder: (context, index){
                                      final image = task.images[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          // child: Image.memory(
                                          //   Uint8List.fromList(image.imageBytes),
                                          //   width: 80,
                                          //   height: 80,
                                          //   fit: BoxFit.cover,
                                          // ),
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Review Notes Section
                      if (task.reviewNotes.isNotEmpty) ...[
                        Container(
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
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Edit Section
                      Container(
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Edit Task',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF495057),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Title',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(color: Color(0xFF6C757D)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: descriptionController,
                                  maxLines: 3,
                                  decoration: const InputDecoration(
                                    labelText: 'Description',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(color: Color(0xFF6C757D)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: TextField(
                                  controller: reviewNotesController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Review Notes',
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(color: Color(0xFF6C757D)),
                                    hintText: 'Add review notes, comments, or observations...',
                                    hintStyle: TextStyle(color: Color(0xFFADB5BD)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  Checkbox(
                                    value: isCompleted,
                                    onChanged: (bool? value){
                                      setState((){
                                        isCompleted = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF28A745),
                                  ),
                                  const Text(
                                    "Mark as completed",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF495057),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: priority,
                                  isExpanded: true,
                                  underline: Container(),
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF6C757D)),
                                  items: levels.map((String level){
                                    return DropdownMenuItem<String>(
                                      value: level,
                                      child: Text(level),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue){
                                    setState((){
                                      priority = newValue!;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Upload Image Button
                              ElevatedButton(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    final bytes = await pickedFile.readAsBytes();
                                    final taskImage = TaskImage(imageBytes: bytes);
                                    taskImage.task.target = task;

                                    final imageId = taskImageBox.put(taskImage);
                                    taskImage.id = imageId;
                                    setState(() {
                                      imageFile = File(pickedFile.path);
                                    });
                                    

                                    // Update task
                                    task.isSynced = false;
                                    task.updatedAt = DateTime.now();
                                    taskBox.put(task);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image uploaded successfully!'),
                                        backgroundColor: Color(0xFF28A745),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Upload Image"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}