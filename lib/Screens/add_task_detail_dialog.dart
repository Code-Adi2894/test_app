import 'package:flutter/material.dart';
import '../entities.dart';
import 'package:test_app/main.dart';

final taskBox = objectbox.store.box<Task>();

void showCustomDialog(BuildContext context, Project project) {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  bool isCompleted = false;
  String priority = "LOW";
  var levels = ["LOW", "MEDIUM", "HIGH"];

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
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text;
                  final description = descriptionController.text;
                  final task = Task(title: title, description: description, isCompleted: isCompleted, priority: priority);
                  try{
                    task.project.target = project;
                    taskBox.put(task);
                    print('Saved input: $title, $description, $isCompleted');
                  } catch(e){
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
