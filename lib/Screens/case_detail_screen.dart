import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import 'package:test_app/widgets/case_detail_case_card.dart';
import 'package:test_app/widgets/task_card.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import '../services/sync_service.dart';
import '../widgets/offline_indicator.dart';
import './tasks_detail_screen.dart';
import './add_task_detail_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final caseBox = objectbox.store.box<Cases>();
final taskBox = objectbox.store.box<Task>();

Stream<List<Task>> getTasksForCase(int caseId) {
  return taskBox.query(Task_.cases.equals(caseId)).watch(triggerImmediately: true).map((q) => q.find());
}

class CaseDetailScreen extends StatefulWidget {
  final Cases case_;

  const CaseDetailScreen({super.key, required this.case_});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  bool _isOnline = true;
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _syncTask(Task task, BuildContext context) async {
    try {
      final success = await syncService.syncTask(task);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Task "${task.title}" synced successfully!'),
            backgroundColor: const Color(0xFF28A745),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Sync failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.case_.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Sync case button - only show when online
          if (_isOnline)
            IconButton(
              onPressed: () => _syncCase(),
              icon: const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sync Case',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Offline indicator
          const OfflineIndicator(),
          Expanded(
            child: Column(
              children: [
                // Case Details Card
                CaseDetailCaseCard(cases: widget.case_),
                // Container(
                //   margin: const EdgeInsets.all(16),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: BorderRadius.circular(16),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.1),
                //         blurRadius: 10,
                //         offset: const Offset(0, 5),
                //       ),
                //     ],
                //   ),
                //   child: Padding(
                //     padding: const EdgeInsets.all(20),
                //     child: Column(
                //       crossAxisAlignment: CrossAxisAlignment.start,
                //       children: [
                //         Row(
                //           children: [
                //             Expanded(
                //               child: Column(
                //                 crossAxisAlignment: CrossAxisAlignment.start,
                //                 children: [
                //                   Text(
                //                     widget.case_.name,
                //                     style: const TextStyle(
                //                       fontSize: 20,
                //                       fontWeight: FontWeight.bold,
                //                       color: Color(0xFF495057),
                //                     ),
                //                   ),
                //                   const SizedBox(height: 4),
                //                   // Text(
                //                   //   'Case Details',
                //                   //   style: const TextStyle(
                //                   //     fontSize: 14,
                //                   //     color: Color(0xFF6C757D),
                //                   //   ),
                //                   // ),
                //                 ],
                //               ),
                //             ),
                //             // Sync status indicator
                //             Container(
                //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                //               decoration: BoxDecoration(
                //                 color: widget.case_.isSynced
                //                   ? const Color(0xFFE8F5E8)
                //                   : const Color(0xFFFFEBEE),
                //                 borderRadius: BorderRadius.circular(12),
                //               ),
                //               child: Row(
                //                 mainAxisSize: MainAxisSize.min,
                //                 children: [
                //                   Icon(
                //                     widget.case_.isSynced ? Icons.check_circle : Icons.sync,
                //                     size: 14,
                //                     color: widget.case_.isSynced
                //                       ? const Color(0xFF28A745)
                //                       : const Color(0xFFDC3545),
                //                   ),
                //                   const SizedBox(width: 4),
                //                   Text(
                //                     widget.case_.isSynced ? 'Synced' : 'Pending',
                //                     style: TextStyle(
                //                       fontSize: 12,
                //                       fontWeight: FontWeight.w600,
                //                       color: widget.case_.isSynced
                //                         ? const Color(0xFF28A745)
                //                         : const Color(0xFFDC3545),
                //                     ),
                //                   ),
                //                 ],
                //               ),
                //             ),
                //           ],
                //         ),
                //         const SizedBox(height: 12),
                //         if (widget.case_.description != null && widget.case_.description!.isNotEmpty)
                //           Text(
                //             widget.case_.description!,
                //             style: const TextStyle(
                //               fontSize: 14,
                //               color: Color(0xFF6C757D),
                //             ),
                //           ),
                //         const SizedBox(height: 8),
                //         if (widget.case_.isSynced)
                //           Text(
                //             'Last synced: ${widget.case_.lastSyncedAt?.toString().substring(0, 19) ?? 'Never'}',
                //             style: const TextStyle(
                //               fontSize: 12,
                //               color: Color(0xFF9E9E9E),
                //             ),
                //           ),
                //       ],
                //     ),
                //   ),
                // ),
                // Tasks Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Row(
                    children: [
                      const Text(
                        'Tasks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF495057),
                        ),
                      ),
                      const Spacer(),
                      StreamBuilder<List<Task>>(
                        stream: getTasksForCase(widget.case_.id),
                        builder: (context, snapshot) {
                          final taskCount = snapshot.data?.length ?? 0;
                          return Text(
                            '$taskCount tasks',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF6C757D),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Tasks List
                Expanded(
                  child: StreamBuilder<List<Task>>(
                    stream: getTasksForCase(widget.case_.id),
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
                                height: 100,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: const Icon(
                                  Icons.task_alt,
                                  size: 50,
                                  color: Color(0xFF2196F3),
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'No tasks yet',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF495057),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap the + button to add your first task',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6C757D),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      }
                      final tasks = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return TaskCard(
                              task: task,
                              onSync: (task) => _syncTask(task, context),
                              isOnline: _isOnline
                          );

                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showCustomDialog(context, widget.case_),
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _syncCase() async {
    try {
      final success = await syncService.syncCase(widget.case_);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case "${widget.case_.name}" synchronized successfully!'),
            backgroundColor: const Color(0xFF28A745),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Sync failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
} 