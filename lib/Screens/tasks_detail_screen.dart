import 'package:flutter/material.dart';
import '../entities.dart';
import '../main.dart';
import '../services/user_service.dart';
import '../widgets/offline_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

final taskBox = objectbox.store.box<Task>();

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

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

  void _saveChanges() {
    widget.task.title = titleController.text;
    widget.task.description = descriptionController.text;
    widget.task.reviewNotes = reviewNotesController.text;
    widget.task.isCompleted = isCompleted;
    widget.task.priority = priority;
    widget.task.updatedAt = DateTime.now();
    widget.task.updatedBy = userService.getCurrentUserEmail(); // Use actual user email
    widget.task.isSynced = false; // Mark as needing sync

    try{
      taskBox.put(widget.task);
      
      // Auto-sync if online
      if (_isOnline) {
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



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.task.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Sync button - only show when online
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
            onPressed: _saveChanges,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Changes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          const OfflineIndicator(),
          Expanded(
            child: SingleChildScrollView(
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
                                      widget.task.title,
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
                              // Sync status indicator
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: widget.task.isSynced 
                                    ? const Color(0xFFE8F5E8) 
                                    : const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      widget.task.isSynced ? Icons.check_circle : Icons.sync,
                                      size: 14,
                                      color: widget.task.isSynced 
                                        ? const Color(0xFF28A745) 
                                        : const Color(0xFFDC3545),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.task.isSynced ? 'Synced' : 'Pending',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: widget.task.isSynced 
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
                            widget.task.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6C757D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Task metadata - Updated timestamp
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: const Color(0xFF9E9E9E),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Updated: ${widget.task.updatedAt.toString().substring(0, 19)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                          // Updated by information - separate row
                          if (widget.task.updatedBy.isNotEmpty) ...[
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
                                    'By: ${widget.task.updatedBy}',
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
                          if (widget.task.isSynced)
                            const SizedBox(height: 8),
                          if (widget.task.isSynced)
                            Text(
                              'Last synced: ${widget.task.updatedAt.toString().substring(0, 19)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9E9E9E),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Review Notes Section
                  if (widget.task.reviewNotes.isNotEmpty) ...[
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
                                  Icons.rate_review,
                                  color: Color(0xFF2196F3),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Review Notes',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF495057),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE0E0E0)),
                              ),
                              child: Text(
                                widget.task.reviewNotes,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF495057),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                          
                          // Title Field
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

                          // Description Field
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

                          // Review Notes Field
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

                          // Completed Checkbox
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

                          // Priority Dropdown
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
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
}