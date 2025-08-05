// lib/screens/case_list_screen.dart

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import 'package:test_app/Screens/login_screen.dart';
import 'package:test_app/widgets/connectivity_indicator.dart';
import 'package:test_app/widgets/site_filter_dropdown.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import '../services/site_service.dart';
import '../widgets/change_notifier.dart';
import './case_detail_screen.dart';
import './add_case_dialog.dart';

final caseBox = objectbox.store.box<Cases>();
Stream<List<Cases>> get caseStream =>
    caseBox.query().watch(triggerImmediately: true).map((q) => q.find());

class CaseListScreen extends StatefulWidget {
  const CaseListScreen({super.key});

  @override
  _CaseListScreenState createState() => _CaseListScreenState();
}

class _CaseListScreenState extends State<CaseListScreen> {
  String? _selectedSite;
  bool _isSyncing = false;
  bool _isOnline = true;
  bool _isAutoSyncing = false;
  late final Connectivity _connectivity;
  late final Stream<List<ConnectivityResult>> _connectivityStream;


  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    // onConnectivityChanged now emits List<ConnectivityResult>
    _connectivityStream = _connectivity.onConnectivityChanged;
    _connectivityStream.listen((results) {
      final wasOffline = !_isOnline;
      setState(() {
        // consider online if there's at least one result that's not `none`
        _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      });
      if (wasOffline && _isOnline) {
        _autoSyncPendingCases();
      }
    });
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    final wasOffline = !_isOnline;
    setState(() {
      _isOnline = results.isNotEmpty && !results.contains(ConnectivityResult.none);
    });
    if (_isOnline && !wasOffline) {
      _autoSyncPendingCases();
    }
  }

  Future<void> _autoSyncPendingCases() async {
    if (!_isOnline || !await syncService.isOnline()) return;

    final pending = caseBox
        .query(Cases_.isSynced.equals(false))
        .build()
        .find();
    if (pending.isEmpty) return;

    setState(() {
      _isSyncing = true;
      _isAutoSyncing = true;
    });

    int count = 0;
    for (var c in pending) {
      if (await syncService.syncCase(c)) count++;
    }
    if (count > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count cases auto-synced successfully!'),
          backgroundColor: const Color(0xFF28A745),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    setState(() {
      _isSyncing = false;
      _isAutoSyncing = false;
    });
  }

  void _showAddCaseDialog(BuildContext ctx) {
    final sites = siteService.getAllSites();
    if (sites.isEmpty) {
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('No Sites Available'),
          content: const Text(
            'Please create a site first in the Sites tab.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    showDialog(
      context: ctx,
      builder: (_) => AddCaseDialog(onCaseAdded: (c) {
        Navigator.pop(ctx);
        if (_isOnline) syncSingleCase(c);
      }),
    );
  }

  void _logout() {
    userService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    try {
      final ok = await syncService.performSync();
      if (!ok) throw Exception('Sync failed');
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
      setState(() => _isSyncing = false);
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...syncOptions.map((option) => ListTile(
              leading: Icon(
                option['icon'] as IconData,
                color: option['enabled']
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFBDBDBD),
              ),
              title: Text(option['title'] as String),
              subtitle: Text(option['subtitle'] as String),
              onTap: option['enabled']
                  ? () {
                Navigator.pop(context);
                _handleSyncOption(option['title'] as String);
              }
                  : null,
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSyncOption(String option) async {
    setState(() => _isSyncing = true);
    try {
      switch (option) {
        case 'Sync All Data':
          await _syncData();
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
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  Future<void> _syncCasesOnly() async {
    final pending = syncService.getPendingCases();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending cases to sync'),
          backgroundColor: Color(0xFF6C757D),
        ),
      );
      return;
    }
    int count = 0;
    for (var c in pending) {
      if (await syncService.syncCase(c)) count++;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count cases synchronized successfully!'),
        backgroundColor: const Color(0xFF28A745),
      ),
    );
  }

  Future<void> _syncTasksOnly() async {
    final pending = syncService.getPendingTasks();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No pending tasks to sync'),
          backgroundColor: Color(0xFF6C757D),
        ),
      );
      return;
    }
    int count = 0;
    for (var t in pending) {
      if (await syncService.syncTask(t)) count++;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$count tasks synchronized successfully!'),
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
                fontWeight: FontWeight.bold,
                color: syncService.hasPendingSyncs()
                    ? const Color(0xFFFFC107)
                    : const Color(0xFF28A745),
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

  void syncSingleCase(Cases c) async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot sync while offline.'),
          backgroundColor: Color(0xFFFF9800),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _isSyncing = true);
    try {
      final ok = await syncService.syncCase(c);
      if (!ok) throw Exception('Sync failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Case "${c.name}" synced!'),
          backgroundColor: const Color(0xFF28A745),
          duration: const Duration(seconds: 2),
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
      setState(() => _isSyncing = false);
    }
  }

  Widget buildSyncStatusIndicator(Cases c) {
    if (!_isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cloud_off, size: 14, color: Color(0xFFFF9800)),
            SizedBox(width: 4),
            Text('Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else {
      final synced = c.isSynced;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: synced ? const Color(0xFFE8F5E8) : const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(synced ? Icons.check_circle : Icons.sync,
                size: 14,
                color: synced ? const Color(0xFF28A745) : const Color(0xFFDC3545)),
            const SizedBox(width: 4),
            Text(
              synced ? 'Synced' : 'Pending',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: synced ? const Color(0xFF28A745) : const Color(0xFFDC3545),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget? buildSyncButton(Cases c) {
    if (!_isOnline || c.isSynced) return null;
    return IconButton(
      onPressed: _isSyncing ? null : () => syncSingleCase(c),
      icon: _isSyncing
          ? const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )
          : const Icon(Icons.sync, color: Color(0xFF2196F3)),
      tooltip: 'Sync Case',
    );
  }

  @override
  Widget build(BuildContext context) {
    var connectionStatus = context.watch<AppStore>().isConnected;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Cases",
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        actions: [
          if (_isAutoSyncing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 6),
                  Text('Auto-syncing', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          IconButton(
            onPressed: () => _showAddCaseDialog(context),
            icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
            tooltip: 'Add Case',
          ),
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _syncData,
              icon: _isSyncing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.sync, color: Color(0xFF2196F3)),
              tooltip: 'Sync All Data',
            ),
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _showSyncOptions,
              icon: const Icon(Icons.more_vert, color: Color(0xFF2196F3)),
              tooltip: 'Sync Options',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SiteFilterDropdown(
              selectedSite: _selectedSite,
              onSiteChanged: (v) => setState(() => _selectedSite = v),
            ),
            // const OfflineIndicator(),
            ConnectivityIndicator(connectivityStatus: connectionStatus),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFF8F9FF), Color(0xFFE8F4FD)],
                  ),
                ),
                child: StreamBuilder<List<Cases>>(
                  stream: caseStream,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    final allCases = snap.data ?? [];
                    final filtered = _selectedSite == null
                        ? allCases
                        : allCases
                        .where((c) => c.site.target?.name == _selectedSite)
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No cases match that site.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final c = filtered[i];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CaseDetailScreen(case_: c)),
                          ),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.07),
                                    blurRadius: 18,
                                    offset: const Offset(0, 6))
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 22),
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
                                                c.name,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            buildSyncStatusIndicator(c),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on,
                                                size: 14,
                                                color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                c.site.target?.name ?? 'No Site',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (c.description != null &&
                                            c.description!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Text(c.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        ],
                                        const SizedBox(height: 8),
                                        Text(
                                          'Created: ${c.createdAt.toString().substring(0, 19)}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF9E9E9E)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Column(
                                    children: [
                                      if (buildSyncButton(c) != null)
                                        buildSyncButton(c)!,
                                      IconButton(
                                        icon: const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            color: Color(0xFF2196F3)),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) =>
                                                  CaseDetailScreen(case_: c)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
