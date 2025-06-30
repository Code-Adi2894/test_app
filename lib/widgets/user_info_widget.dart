import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../services/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UserInfoWidget extends StatefulWidget {
  const UserInfoWidget({super.key});

  @override
  State<UserInfoWidget> createState() => _UserInfoWidgetState();
}

class _UserInfoWidgetState extends State<UserInfoWidget> {
  bool _isOnline = true;
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _checkConnectivity();
    _connectivity.onConnectivityChanged.listen((results) {
      setState(() {
        _isOnline = results.isNotEmpty && results.first != ConnectivityResult.none;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = userService.currentUser;
    final stats = syncService.getSyncStats();
    final hasPendingSyncs = syncService.hasPendingSyncs();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          if (currentUser != null) ...[
            Row(
              children: [
                const Icon(
                  Icons.person,
                  size: 16,
                  color: Color(0xFF6C757D),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Logged in as: ${currentUser.email}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF495057),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          
          // Connectivity status
          Row(
            children: [
              Icon(
                _isOnline ? Icons.wifi : Icons.wifi_off,
                size: 16,
                color: _isOnline 
                  ? const Color(0xFF28A745) 
                  : const Color(0xFFDC3545),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isOnline 
                      ? const Color(0xFF28A745) 
                      : const Color(0xFFDC3545),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Sync status
          Row(
            children: [
              Icon(
                hasPendingSyncs ? Icons.sync : Icons.check_circle,
                size: 16,
                color: hasPendingSyncs 
                  ? const Color(0xFFFFC107) 
                  : const Color(0xFF28A745),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  syncService.getSyncStatusMessage(),
                  style: TextStyle(
                    fontSize: 14,
                    color: hasPendingSyncs 
                      ? const Color(0xFFFFC107) 
                      : const Color(0xFF28A745),
                  ),
                ),
              ),
            ],
          ),
          
          // Sync statistics
          if (hasPendingSyncs) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFFC107)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pending Sync:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF856404),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• ${stats['pendingCases']} cases pending',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856404),
                    ),
                  ),
                  Text(
                    '• ${stats['pendingTasks']} tasks pending',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF856404),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
} 