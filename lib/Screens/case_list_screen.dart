import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import '../services/site_service.dart';
import './case_detail_screen.dart';
import './login_screen.dart';
import '../widgets/offline_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import './add_case_dialog.dart';

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
    if (!await syncService.isOnline()) {
      return; // Don't auto-sync if offline
    }

    final pendingCases = caseBox.query(Cases_.isSynced.equals(false)).build().find();
    if (pendingCases.isNotEmpty) {
      setState(() {
        _isSyncing = true;
        _isAutoSyncing = true;
      });

      try {
        for (var case_ in pendingCases) {
          await syncService.syncCase(case_);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pendingCases.length} cases auto-synced successfully!'),
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
    // Check if there are any sites available
    final sites = siteService.getAllSites();
    if (sites.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Sites Available'),
          content: const Text(
            'You need to create at least one site before adding cases. '
            'Please go to the Sites tab and create a site first.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddCaseDialog(
        onCaseAdded: (case_) {
          Navigator.of(context).pop();
          // The case is already saved in the dialog
        },
      ),
    );
  }

  void _logout() {
    userService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  // Simple global sync function - one click sync all data
  void _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await syncService.performSync();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data synchronized successfully!'),
            backgroundColor: Color(0xFF28A745),
          ),
        );
      } else {
        throw Exception('Sync operation failed');
      }
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
    final syncOptions = syncService.getSyncOptions();
    
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
            ...syncOptions.map((option) => ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: option['enabled'] 
                  ? const Color(0xFF2196F3) 
                  : const Color(0xFFBDBDBD),
              ),
              title: Text(
                option['title'] as String,
                style: TextStyle(
                  color: option['enabled'] 
                    ? const Color(0xFF222B45) 
                    : const Color(0xFFBDBDBD),
                ),
              ),
              subtitle: Text(
                option['subtitle'] as String,
                style: TextStyle(
                  color: option['enabled'] 
                    ? const Color(0xFF6C757D) 
                    : const Color(0xFFBDBDBD),
                ),
              ),
              onTap: option['enabled'] ? () {
                Navigator.pop(context);
                _handleSyncOption(option['title'] as String);
              } : null,
            )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _handleSyncOption(String option) async {
    setState(() {
      _isSyncing = true;
    });

    try {
      switch (option) {
        case 'Sync All Data':
          await _syncAllData();
          break;
        case 'Sync Cases Only':
          await _syncCasesOnly();
          break;
        case 'Sync Tasks Only':
          await _syncTasksOnly();
          break;
        case 'View Sync Status':
          _showSyncStatus();
          break;
      }
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

  Future<void> _syncAllData() async {
    final success = await syncService.performSync();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All data synchronized successfully!'),
          backgroundColor: Color(0xFF28A745),
        ),
      );
    } else {
      throw Exception('Sync operation failed');
    }
  }

  Future<void> _syncCasesOnly() async {
    final pendingCases = syncService.getPendingCases();
    if (pendingCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending cases to sync'),
          backgroundColor: Color(0xFF6C757D),
        ),
      );
      return;
    }

    int syncedCount = 0;
    for (var case_ in pendingCases) {
      final success = await syncService.syncCase(case_);
      if (success) syncedCount++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$syncedCount cases synchronized successfully!'),
        backgroundColor: const Color(0xFF28A745),
      ),
    );
  }

  Future<void> _syncTasksOnly() async {
    final pendingTasks = syncService.getPendingTasks();
    if (pendingTasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending tasks to sync'),
          backgroundColor: Color(0xFF6C757D),
        ),
      );
      return;
    }

    int syncedCount = 0;
    for (var task in pendingTasks) {
      final success = await syncService.syncTask(task);
      if (success) syncedCount++;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$syncedCount tasks synchronized successfully!'),
        backgroundColor: const Color(0xFF28A745),
      ),
    );
  }

  void _showSyncStatus() {
    final stats = syncService.getSyncStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Cases: ${stats['totalCases']}'),
            Text('Synced Cases: ${stats['syncedCases']}'),
            Text('Pending Cases: ${stats['pendingCases']}'),
            const SizedBox(height: 16),
            Text('Total Tasks: ${stats['totalTasks']}'),
            Text('Synced Tasks: ${stats['syncedTasks']}'),
            Text('Pending Tasks: ${stats['pendingTasks']}'),
            const SizedBox(height: 16),
            Text(
              'Status: ${syncService.getSyncStatusMessage()}',
              style: TextStyle(
                color: syncService.hasPendingSyncs() 
                  ? const Color(0xFFFFC107) 
                  : const Color(0xFF28A745),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _syncSingleCase(Cases case_) async {
    try {
      final success = await syncService.syncCase(case_);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case "${case_.name}" synchronized successfully!'),
            backgroundColor: const Color(0xFF28A745),
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
        ),
      );
    }
  }

  void _updateCaseWithAutoSync(Cases case_) async {
    case_.updatedAt = DateTime.now();
    case_.isSynced = false; // Mark as needing sync
    case_.syncStatus = 'pending';
    
    caseBox.put(case_);
    
    // Auto-sync if online
    if (await syncService.isOnline()) {
      _autoSyncSingleCase(case_);
    }
  }

  void _autoSyncSingleCase(Cases case_) async {
    setState(() {
      _isAutoSyncing = true;
    });
    
    try {
      final success = await syncService.syncCase(case_);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Case "${case_.name}" auto-synced!'),
            backgroundColor: const Color(0xFF28A745),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Don't show error for auto-sync, just log it
      print('Auto-sync failed for case ${case_.name}: $e');
    } finally {
      setState(() {
        _isAutoSyncing = false;
      });
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
          // Global sync button - simple one-click sync
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _syncData,
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
              tooltip: 'Sync All Data',
            ),
          // Sync options button - detailed sync options
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _showSyncOptions,
              icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
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
                                        // Site information
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey[600],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                case_.site.target?.name ?? 'No Site',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (case_.description != null && case_.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            case_.description!,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF6C757D),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
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