import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import './tasks_list_screen.dart';

final projectBox = objectbox.store.box<Project>();

Stream<List<Project>> get projectStream => projectBox.query().watch(triggerImmediately: true).map((q)=> q.find());

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
                    try{
                      projectBox.put(project);
                      print('Saved input: $input');
                    }catch(e) {
                      print("Error $e");
                    }
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
    late Project selectedProject;
    return Scaffold(
        appBar: AppBar(title: const Text("Project list")),
        body: Column(
            children: [
              Expanded(child: StreamBuilder<List<Project>>(
                stream: projectStream,
                builder: (context, snapshot){
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No tasks found.'));
                  }
                  final projects = snapshot.data!;
                  return ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) => ListTile(
                      title: Text(projects[index].name),
                        onTap: (){
                          selectedProject = projects[index];
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => TasksListScreen(project: selectedProject))
                          );
                        }
                    ),
                  );
                }
              )),
              ElevatedButton(
                  onPressed: () => openAddProjectDialog(context),
                  child: Text("Add project")
              )
            ]
        )
    );
  }
}


