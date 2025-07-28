// import 'dart:io';
import 'package:flutter/material.dart';
import '../entities.dart';
import 'package:test_app/main.dart';
import '../services/user_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';

final taskBox = objectbox.store.box<Task>();

void showCustomDialog(BuildContext context, Cases case_, bool isOnline) {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController reviewNotesController = TextEditingController();
  bool isCompleted = false;
  String priority = "LOW";
  var levels = ["LOW", "MEDIUM", "HIGH"];
  // bool isOnline = true;


  showDialog(
    context: context,
    barrierDismissible: false, // Prevent accidental dismissal
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFFF8F9FA),
            title: const Text(
              'New Task',
              style: TextStyle(color: Color(0xFF495057)),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reviewNotesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Review Notes',
                      border: OutlineInputBorder(),
                      hintText: 'Add review notes, comments, or observations...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: isCompleted,
                        onChanged: (bool? value) {
                          setState(() {
                            isCompleted = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF28A745),
                      ),
                      const Text('Completed'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: priority,
                      isExpanded: true,
                      underline: Container(),
                      icon: const Icon(Icons.keyboard_arrow_down),
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
                      }
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final title = titleController.text.trim();
                  final description = descriptionController.text.trim();
                  
                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a title'),
                        backgroundColor: Color(0xFFDC3545),
                      ),
                    );
                    return;
                  }

                  final task = Task(
                    title: title, 
                    description: description, 
                    reviewNotes: reviewNotesController.text.trim(),
                    isCompleted: isCompleted, 
                    priority: priority,
                    isSynced: false, // Mark as needing sync
                    updatedAt: DateTime.now(),
                    updatedBy: userService.getCurrentUserEmail(), // Use actual user email
                  );

                  try {
                    print("isOnline: $isOnline");
                    task.cases.target = case_;
                    taskBox.put(task);
                    
                    Navigator.pop(context);
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Task "$title" created successfully!'),
                        backgroundColor: const Color(0xFF28A745),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    
                    // Auto-sync if online
                    if (isOnline) {
                      print('isonline: $isOnline');
                      _autoSyncTask(task);
                    }
                  } catch(e) {
                    print("Error $e");
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error creating task: $e'),
                        backgroundColor: const Color(0xFFDC3545),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}

void _autoSyncTask(Task task) async {
  try {
    final success = await syncService.syncTask(task);
    if (success) {
      // Note: We can't show SnackBar here as the context is no longer available
      print('Task "${task.title}" auto-synced!');
    } else {
      print('Auto-sync failed for task ${task.title}');
    }
  } catch (e) {
    print('Auto-sync failed for task ${task.title}: $e');
  }
}
