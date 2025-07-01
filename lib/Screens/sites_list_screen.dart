import 'package:flutter/material.dart';
import '../entities.dart';
import '../services/site_service.dart';
import '../services/sync_service.dart';
import 'add_site_dialog.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  List<Site> sites = [];
  bool _isSyncing = false;
  bool _isOnline = true;
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _loadSites();
    _checkConnectivity();
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  void _loadSites() {
    setState(() {
      sites = siteService.getAllSites();
    });
  }

  void _showAddSiteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSiteDialog(
        onSiteAdded: (site) {
          _loadSites();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _deleteSite(Site site) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              siteService.deleteSite(site.id);
              _loadSites();
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _syncSites() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final pendingSites = syncService.getPendingSites();
      if (pendingSites.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No sites to sync'),
            backgroundColor: Color(0xFF6C757D),
          ),
        );
        return;
      }

      int syncedCount = 0;
      for (var site in pendingSites) {
        final success = await syncService.syncSite(site);
        if (success) syncedCount++;
      }

      _loadSites(); // Refresh the list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$syncedCount sites synchronized successfully!'),
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

  void _syncSingleSite(Site site) async {
    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await syncService.syncSite(site);
      if (success) {
        _loadSites(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Site synchronized successfully!'),
            backgroundColor: Color(0xFF28A745),
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
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sites'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Global sync button
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _syncSites,
              icon: _isSyncing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.sync, color: Colors.white),
              tooltip: 'Sync All Sites',
            ),
        ],
      ),
      body: sites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No sites yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first site',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF2196F3),
                      child: Text(
                        site.name.isNotEmpty ? site.name[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            site.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Sync status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: site.isSynced 
                              ? const Color(0xFFE8F5E8) 
                              : const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                site.isSynced ? Icons.check_circle : Icons.sync,
                                size: 14,
                                color: site.isSynced 
                                  ? const Color(0xFF28A745) 
                                  : const Color(0xFFDC3545),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                site.isSynced ? 'Synced' : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: site.isSynced 
                                    ? const Color(0xFF28A745) 
                                    : const Color(0xFFDC3545),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (site.address != null && site.address!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    site.address!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (site.description != null && site.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              site.description!,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Created: ${_formatDate(site.createdAt)}',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Individual sync button - only show when online and not synced
                        if (_isOnline && !site.isSynced)
                          IconButton(
                            icon: Icon(
                              Icons.sync,
                              color: !_isSyncing 
                                ? const Color(0xFF2196F3) 
                                : const Color(0xFFB0BEC5),
                            ),
                            onPressed: !_isSyncing 
                              ? () => _syncSingleSite(site)
                              : null,
                            tooltip: 'Sync this site',
                          ),
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'delete') {
                              _deleteSite(site);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSiteDialog,
        backgroundColor: const Color(0xFF2196F3),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 