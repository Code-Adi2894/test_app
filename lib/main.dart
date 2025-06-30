import 'dart:io';

import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:test_app/Screens/login_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'objectbox.dart';
import 'services/user_service.dart';

late ObjectBox objectbox;

// Global connectivity service
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  bool _isOnline = true;

  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    // Check initial connectivity
    await _checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;
  }
}

// Global instance
final connectivityService = ConnectivityService();

Future<void>  main() async{
  WidgetsFlutterBinding.ensureInitialized();

  objectbox = await ObjectBox.create();
  
  // Initialize connectivity service
  await connectivityService.initialize();

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
  
  // Debug: Print user information
  _debugUserInfo();
  
  printLocalPath();
  runApp(const MyApp());
}

void _debugUserInfo() {
  try {
    final userCount = userService.getUserCount();
    final allUsers = userService.getAllUsers();
    
    print('=== DEBUG USER INFO ===');
    print('Total users in database: $userCount');
    for (var user in allUsers) {
      print('User ID: ${user.id}, Email: ${user.email}');
    }
    print('=======================');
  } catch (e) {
    print('Error getting user info: $e');
  }
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



