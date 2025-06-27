// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../entities.dart';
import 'package:test_app/main.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final taskBox = objectbox.store.box<Task>();
final taskImageBox = objectbox.store.box<TaskImage>();

void showCustomDialog(BuildContext context, Cases case_) {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isCompleted = false;
  String priority = "LOW";
  var levels = ["LOW", "MEDIUM", "HIGH"];
  List<Uint8List> selectedImages = [];
  bool _isOnline = true;

  // Check connectivity
  Connectivity().checkConnectivity().then((result) {
    _isOnline = result != ConnectivityResult.none;
  });

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
                  const SizedBox(height: 16),
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: ElevatedButton.icon(
                  //         onPressed: () async {
                  //           try {
                  //             final picker = ImagePicker();
                  //             final pickedFile = await picker.pickImage(
                  //               source: ImageSource.gallery,
                  //               maxWidth: 1024, // Limit image size
                  //               maxHeight: 1024,
                  //               imageQuality: 85, // Compress image
                  //             );
                  //             if (pickedFile != null) {
                  //               final bytes = await pickedFile.readAsBytes();
                  //               setState(() {
                  //                 selectedImages.add(bytes);
                  //               });
                  //             }
                  //           } catch (e) {
                  //             print('Error picking image: $e');
                  //             ScaffoldMessenger.of(context).showSnackBar(
                  //               SnackBar(
                  //                 content: Text('Error selecting image: $e'),
                  //                 backgroundColor: const Color(0xFFDC3545),
                  //               ),
                  //             );
                  //           }
                  //         },
                  //         icon: const Icon(Icons.add_photo_alternate),
                  //         label: const Text("Add Image"),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: const Color(0xFF2196F3),
                  //           foregroundColor: Colors.white,
                  //         ),
                  //       ),
                  //     ),
                  //     if (selectedImages.isNotEmpty) ...[
                  //       const SizedBox(width: 8),
                  //       ElevatedButton.icon(
                  //         onPressed: () {
                  //           setState(() {
                  //             selectedImages.clear();
                  //           });
                  //         },
                  //         icon: const Icon(Icons.clear_all),
                  //         label: const Text("Clear All"),
                  //         style: ElevatedButton.styleFrom(
                  //           backgroundColor: const Color(0xFFDC3545),
                  //           foregroundColor: Colors.white,
                  //         ),
                  //       ),
                  //     ],
                  //   ],
                  // ),
                  // if (selectedImages.isNotEmpty) ...[
                  //   const SizedBox(height: 16),
                  //   const Text(
                  //     'Selected Images:',
                  //     style: TextStyle(
                  //       fontWeight: FontWeight.bold,
                  //       color: Color(0xFF495057),
                  //     ),
                  //   ),
                  //   const SizedBox(height: 8),
                  //   SizedBox(
                  //     height: 100,
                  //     child: ListView.builder(
                  //       scrollDirection: Axis.horizontal,
                  //       itemCount: selectedImages.length,
                  //       itemBuilder: (context, index) {
                  //         return Stack(
                  //           children: [
                  //             Container(
                  //               margin: const EdgeInsets.only(right: 8),
                  //               width: 100,
                  //               height: 100,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(8),
                  //                 border: Border.all(color: const Color(0xFFE0E0E0)),
                  //               ),
                  //               child: ClipRRect(
                  //                 borderRadius: BorderRadius.circular(8),
                  //                 child: Image.memory(
                  //                   selectedImages[index],
                  //                   fit: BoxFit.cover,
                  //                   errorBuilder: (context, error, stackTrace) {
                  //                     return Container(
                  //                       color: const Color(0xFFF5F5F5),
                  //                       child: const Icon(
                  //                         Icons.broken_image,
                  //                         color: Color(0xFF9E9E9E),
                  //                       ),
                  //                     );
                  //                   },
                  //                 ),
                  //               ),
                  //             ),
                  //             Positioned(
                  //               top: 4,
                  //               right: 12,
                  //               child: GestureDetector(
                  //                 onTap: () {
                  //                   setState(() {
                  //                     selectedImages.removeAt(index);
                  //                   });
                  //                 },
                  //                 child: Container(
                  //                   padding: const EdgeInsets.all(2),
                  //                   decoration: const BoxDecoration(
                  //                     color: Color(0xFFDC3545),
                  //                     shape: BoxShape.circle,
                  //                   ),
                  //                   child: const Icon(
                  //                     Icons.close,
                  //                     size: 16,
                  //                     color: Colors.white,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           ],
                  //         );
                  //       },
                  //     ),
                  //   ),
                  // ],
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
                    isCompleted: isCompleted, 
                    priority: priority,
                    isSynced: false, // Mark as needing sync
                    syncStatus: 'pending', // Set initial sync status
                    updatedAt: DateTime.now(),
                  );

                  try {
                    task.cases.target = case_;
                    taskBox.put(task);
                    
                    // Save images
                    for(final bytes in selectedImages){
                      final taskImage = TaskImage(imageBytes: bytes);
                      taskImage.task.target = task;
                      taskImageBox.put(taskImage);
                    }
                    
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
                    if (_isOnline) {
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
    final syncTime = DateTime.now();
    task.isSynced = true;
    task.syncStatus = 'synced';
    task.updatedAt = syncTime;
    
    taskBox.put(task);
    
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    // Note: We can't show SnackBar here as the context is no longer available
    print('Task "${task.title}" auto-synced!');
  } catch (e) {
    print('Auto-sync failed for task ${task.title}: $e');
  }
}
