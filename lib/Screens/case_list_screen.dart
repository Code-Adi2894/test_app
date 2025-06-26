import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import './case_detail_screen.dart';
import './login_screen.dart';
import '../widgets/offline_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final caseBox = objectbox.store.box<Cases>();
final taskBox = objectbox.store.box<Task>();

Stream<List<Cases>> get caseStream => caseBox.query().watch(triggerImmediately: true).map((q)=> q.find());

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  State<CaseListScreen> createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  bool _isSyncing = false;
  bool _isOnline = true;
  bool _isAutoSyncing = false;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((results) {
      final wasOffline = !_isOnline;
      setState(() {
        _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
      });
      
      // Auto-sync when coming back online
      if (wasOffline && _isOnline) {
        _autoSyncPendingCases();
      }
    });
    // Check initial status
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    final wasOffline = !_isOnline;
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
    
    // Auto-sync if we're online initially and have pending cases
    if (_isOnline && !wasOffline) {
      _autoSyncPendingCases();
    }
  }

  void _autoSyncPendingCases() async {
    final pendingCases = caseBox.query(Cases_.isSynced.equals(false)).build().find();
    if (pendingCases.isNotEmpty) {
      setState(() {
        _isSyncing = true;
        _isAutoSyncing = true;
      });

      try {
        final syncTime = DateTime.now();
        int totalTasksSynced = 0;
        
        for (var case_ in pendingCases) {
          case_.isSynced = true;
          case_.lastSyncedAt = syncTime;
          case_.syncStatus = 'synced';
          case_.updatedAt = syncTime;
          
          // Sync all tasks in this case
          final tasks = taskBox.query(Task_.cases.equals(case_.id)).build().find();
          for (var task in tasks) {
            task.isSynced = true;
            task.updatedAt = syncTime;
          }
          taskBox.putMany(tasks);
          totalTasksSynced += tasks.length;
        }
        
        caseBox.putMany(pendingCases);
        
        await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pendingCases.length} cases and $totalTasksSynced tasks auto-synced successfully!'),
            backgroundColor: const Color(0xFF28A745),
            duration: const Duration(seconds: 3),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auto-sync failed: $e'),
            backgroundColor: const Color(0xFFDC3545),
            duration: const Duration(seconds: 3),
          ),
        );
      } finally {
        setState(() {
          _isSyncing = false;
          _isAutoSyncing = false;
        });
      }
    }
  }

  void _showAddCaseDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8F9FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Add Case",
            style: TextStyle(
              color: Color(0xFF495057),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                String title = titleController.text.trim();
                String description = descriptionController.text.trim();
                if (title.isNotEmpty) {
                  final case_ = Cases(name: title, description: description);
                  try {
                    caseBox.put(case_);
                    
                    // Auto-sync new case if online
                    if (_isOnline) {
                      _autoSyncSingleCase(case_);
                    }
                  } catch (e) {
                    print("Error $e");
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // Simulate sync operation
      await Future.delayed(const Duration(seconds: 2));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data synchronized successfully!'),
          backgroundColor: Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showSyncOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Sync Options',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF222B45),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.sync, color: Color(0xFF2196F3)),
              title: const Text('Sync All Cases'),
              subtitle: const Text('Sync all cases with latest timestamps'),
              onTap: () {
                Navigator.pop(context);
                _syncAllCases();
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt, color: Color(0xFF2196F3)),
              title: const Text('Sync Individual Cases'),
              subtitle: const Text('Choose specific cases to sync'),
              onTap: () {
                Navigator.pop(context);
                _showIndividualSyncDialog();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _syncAllCases() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final cases = caseBox.getAll();
      final syncTime = DateTime.now();
      
      for (var case_ in cases) {
        case_.isSynced = true;
        case_.lastSyncedAt = syncTime;
        case_.syncStatus = 'synced';
        case_.updatedAt = syncTime;
        
        // Sync all tasks in this case
        final tasks = taskBox.query(Task_.cases.equals(case_.id)).build().find();
        for (var task in tasks) {
          task.isSynced = true;
          task.updatedAt = syncTime;
        }
        taskBox.putMany(tasks);
      }
      
      caseBox.putMany(cases);
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cases.length} cases and their tasks synchronized successfully!'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showIndividualSyncDialog() {
    final cases = caseBox.getAll();
    final selectedCases = <Cases>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFFF8F9FA),
          title: const Text(
            'Select Cases to Sync',
            style: TextStyle(color: Color(0xFF495057)),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: cases.length,
              itemBuilder: (context, index) {
                final case_ = cases[index];
                final taskCount = taskBox.query(Task_.cases.equals(case_.id)).build().count();
                return CheckboxListTile(
                  title: Text(case_.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        case_.isSynced 
                          ? 'Last synced: ${case_.lastSyncedAt?.toString().substring(0, 19) ?? 'Never'}'
                          : 'Not synced',
                        style: TextStyle(
                          color: case_.isSynced ? const Color(0xFF28A745) : const Color(0xFFDC3545),
                        ),
                      ),
                      Text(
                        '$taskCount task${taskCount != 1 ? 's' : ''}',
                        style: const TextStyle(
                          color: Color(0xFF6C757D),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  value: selectedCases.contains(case_),
                  onChanged: (bool? value) {
                    setDialogState(() {
                      if (value == true) {
                        selectedCases.add(case_);
                      } else {
                        selectedCases.remove(case_);
                      }
                    });
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedCases.isEmpty ? null : () {
                Navigator.pop(context);
                _syncSelectedCases(selectedCases.toList());
              },
              child: const Text('Sync Selected'),
            ),
          ],
        ),
      ),
    );
  }

  void _syncSelectedCases(List<Cases> casesToSync) async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final syncTime = DateTime.now();
      int totalTasksSynced = 0;
      
      for (var case_ in casesToSync) {
        case_.isSynced = true;
        case_.lastSyncedAt = syncTime;
        case_.syncStatus = 'synced';
        case_.updatedAt = syncTime;
        
        // Sync all tasks in this case
        final tasks = taskBox.query(Task_.cases.equals(case_.id)).build().find();
        for (var task in tasks) {
          task.isSynced = true;
          task.updatedAt = syncTime;
        }
        taskBox.putMany(tasks);
        totalTasksSynced += tasks.length;
      }
      
      caseBox.putMany(casesToSync);
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate network delay
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${casesToSync.length} cases and $totalTasksSynced tasks synchronized successfully!'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _syncSingleCase(Cases case_) async {
    try {
      final syncTime = DateTime.now();
      case_.isSynced = true;
      case_.lastSyncedAt = syncTime;
      case_.syncStatus = 'synced';
      case_.updatedAt = syncTime;
      
      // Sync all tasks in this case
      final tasks = taskBox.query(Task_.cases.equals(case_.id)).build().find();
      for (var task in tasks) {
        task.isSynced = true;
        task.updatedAt = syncTime;
      }
      taskBox.putMany(tasks);
      
      caseBox.put(case_);
      
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case "${case_.name}" and ${tasks.length} tasks synchronized successfully!'),
          backgroundColor: const Color(0xFF28A745),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
        ),
      );
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFF8F9FA),
        title: const Text('Logout', style: TextStyle(color: Color(0xFF6C757D))),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: Color(0xFF495057)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6C757D))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC3545),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _autoSyncSingleCase(Cases case_) async {
    setState(() {
      _isAutoSyncing = true;
    });
    
    try {
      final syncTime = DateTime.now();
      case_.isSynced = true;
      case_.lastSyncedAt = syncTime;
      case_.syncStatus = 'synced';
      case_.updatedAt = syncTime;
      
      // Sync all tasks in this case
      final tasks = taskBox.query(Task_.cases.equals(case_.id)).build().find();
      for (var task in tasks) {
        task.isSynced = true;
        task.updatedAt = syncTime;
      }
      taskBox.putMany(tasks);
      
      caseBox.put(case_);
      
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case "${case_.name}" and ${tasks.length} tasks auto-synced!'),
          backgroundColor: const Color(0xFF28A745),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Don't show error for auto-sync, just log it
      print('Auto-sync failed for case ${case_.name}: $e');
    } finally {
      setState(() {
        _isAutoSyncing = false;
      });
    }
  }

  void _updateCaseWithAutoSync(Cases case_) async {
    case_.updatedAt = DateTime.now();
    case_.isSynced = false; // Mark as needing sync
    case_.syncStatus = 'pending';
    
    caseBox.put(case_);
    
    // Auto-sync if online
    if (_isOnline) {
      _autoSyncSingleCase(case_);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Remove back icon
        title: const Text(
          "Cases",
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          // Auto-sync indicator
          if (_isAutoSyncing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Auto-syncing',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
            ),
          // Add case button
          IconButton(
            onPressed: () => _showAddCaseDialog(context),
            icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
            tooltip: 'Add Case',
          ),
          // Only show sync button when online
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _showSyncOptions,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    )
                  : const Icon(Icons.sync, color: Color(0xFF2196F3)),
              tooltip: 'Sync Options',
            ),
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(0xFF2196F3)),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          const OfflineIndicator(),
          Expanded(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFB3E5FC),
                    Color(0xFF81D4FA),
                  ],
                ),
              ),
              child: StreamBuilder<List<Cases>>(
                stream: caseStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2196F3)),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Color(0xFF6C757D),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: const TextStyle(color: Color(0xFF6C757D)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 120,
                            width: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(60),
                            ),
                            child: const Icon(
                              Icons.folder_open,
                              size: 60,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No cases found',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222B45),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Tap the + button to create your first case',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6C757D),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  final cases = snapshot.data!;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    child: ListView.builder(
                      itemCount: cases.length,
                      itemBuilder: (context, index) {
                        final case_ = cases[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CaseDetailScreen(case_: case_),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                case_.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF222B45),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Sync status indicator
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: case_.isSynced 
                                                  ? const Color(0xFFE8F5E8) 
                                                  : const Color(0xFFFFEBEE),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    case_.isSynced ? Icons.check_circle : Icons.sync,
                                                    size: 14,
                                                    color: case_.isSynced 
                                                      ? const Color(0xFF28A745) 
                                                      : const Color(0xFFDC3545),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    case_.isSynced ? 'Synced' : 'Pending',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: case_.isSynced 
                                                        ? const Color(0xFF28A745) 
                                                        : const Color(0xFFDC3545),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          case_.description ?? '',
                                          style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF6C757D),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        // Last synced timestamp
                                        if (case_.isSynced && case_.lastSyncedAt != null)
                                          Text(
                                            'Last synced: ${case_.lastSyncedAt!.toString().substring(0, 19)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9E9E9E),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      // Individual sync button - only show when online
                                      if (_isOnline)
                                        IconButton(
                                          icon: Icon(
                                            Icons.sync,
                                            color: !_isSyncing 
                                              ? const Color(0xFF2196F3) 
                                              : const Color(0xFFB0BEC5),
                                          ),
                                          onPressed: !_isSyncing 
                                            ? () => _syncSingleCase(case_)
                                            : null,
                                          tooltip: 'Sync this case',
                                        ),
                                      const SizedBox(height: 8),
                                      // View case button
                                      IconButton(
                                        icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF2196F3)),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => CaseDetailScreen(case_: case_),
                                            ),
                                          );
                                        },
                                        tooltip: 'View',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
} 