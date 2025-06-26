// import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../entities.dart';
import 'package:test_app/main.dart';
import 'package:image_picker/image_picker.dart';


final taskBox = objectbox.store.box<Task>();
final taskImageBox = objectbox.store.box<TaskImage>();

void showCustomDialog(BuildContext context, Cases case_) {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isCompleted = false;
  String priority = "LOW";
  var levels = ["LOW", "MEDIUM", "HIGH"];
  // File? imageFile;
  List<Uint8List> selectedImages = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('New Task'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: isCompleted,
                        onChanged: (bool? value) {
                          setState(() {
                            isCompleted = value ?? false;
                          });
                        },
                      ),
                      const Text('Completed'),
                    ],
                  ),
                  DropdownButton(
                      value: priority,
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
                  ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setState(() {
                            selectedImages.add(bytes);
                          });
                        }
                      },
                      child: Text("Upload images")
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
                  final title = titleController.text;
                  final description = descriptionController.text;
                  final task = Task(title: title, description: description, isCompleted: isCompleted, priority: priority);

                  try {
                    task.cases.target = case_;
                    taskBox.put(task);
                    for(final bytes in selectedImages){
                      final taskImage = TaskImage(imageBytes: bytes);
                      taskImage.task.target = task;
                      taskImageBox.put(taskImage);
                    }
                  }catch(e){
                    print("Error $e");
                  }
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
