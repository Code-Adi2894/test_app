import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../entities.dart';
import '../main.dart';
import 'dart:typed_data';

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
  bool isCompleted = false;
  String priority = '';
  var levels = ["LOW", "MEDIUM", "HIGH"];
  List<int> images = [];
  File? imageFile;

  @override
  void initState(){
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    isCompleted = widget.task.isCompleted;
    priority = widget.task.priority;
    print(widget.task.images.length);
  }

  @override
  void dispose(){
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold (
      appBar: AppBar(title: Text("Task detail")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            )
          ),
          Padding(
              padding: EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text("Completed"),
                  Checkbox(
                      value: isCompleted,
                      onChanged: (bool? value){
                        setState((){
                          isCompleted = value ?? false;
                        });
                      }
                  )
                ]
              )
          ),
          Padding(
              padding: EdgeInsets.all(16.0),
              child: DropdownButton(
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
          ),

          if(widget.task.images.isNotEmpty)
            Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.task.images.length,
                    itemBuilder: (context, index){
                      final image = widget.task.images[index];
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal:4),
                        child: ClipRRect(
                          child: Image.memory(
                            Uint8List.fromList(image.imageBytes),
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                      )
                      );
                    }
                  )
                )
            ),





          ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    imageFile = File(pickedFile.path);
                  });
                }
              },
              child: Text("Upload images")
          ),
          Expanded(child: Container(),),
          ElevatedButton(
            onPressed: (){
              widget.task.title = titleController.text;
              widget.task.description = descriptionController.text;
              widget.task.isCompleted = isCompleted;
              widget.task.priority = priority;



              try{
                taskBox.put(widget.task);
                Navigator.pop(context);
                print("Updated task");
              }catch(e){
                print("Error: $e");
              }
            },
            child: Text("Save changes")
          )
        ],
      )
    );
  }
}