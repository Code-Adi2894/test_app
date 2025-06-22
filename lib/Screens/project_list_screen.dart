import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';

final projectBox = objectbox.store.box<Project>();

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  void openAddProjectDialog(BuildContext context) async {
    TextEditingController _controller = TextEditingController();

    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              title: Text("Add project"),
              content: TextField(
                controller: _controller,
                decoration: InputDecoration(hintText: "Add project name"),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () {
                    String input = _controller.text;
                    final project = Project(name: input);
                    projectBox.put(project);
                    print('Saved input: $input');
                    Navigator.of(context).pop();
                  },
                  child: Text('SAVE'),
                ),

              ]
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Project list")),
        body: Column(
            children: [
              // Expanded(child: ),
              ElevatedButton(
                  onPressed: () => openAddProjectDialog(context),
                  child: Text("Add project")
              )
            ]
        )
    );
  }
}


