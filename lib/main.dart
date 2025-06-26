import 'dart:io';

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:test_app/Screens/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'objectbox.dart';

late ObjectBox objectbox;

Future<void>  main() async{
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();

  var syncServerIp = Platform.isAndroid ? "10.0.2.2" : "127.0.0.1";
  SyncClient syncClient = Sync.client(
      objectbox.store,
      'ws://$syncServerIp:9999',
      SyncCredentials.none()
  );

  try{
    syncClient.start();
    print("Sync client started");
  } catch(e){
    print("Sync client error: $e");
  }
  printLocalPath();
  runApp(const MyApp());
}

Future<void> printLocalPath() async {
  final directory = await getApplicationDocumentsDirectory();
  print('Local path: ${directory.path}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test app with flutter',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: LoginScreen(),
    );
  }
}



