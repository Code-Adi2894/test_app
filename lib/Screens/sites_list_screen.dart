import 'package:flutter/material.dart';
import 'package:test_app/main.dart';
import '../entities.dart';
import '../objectbox.g.dart';
import '../services/site_service.dart';
import 'add_site_dialog.dart';

final siteBox = objectbox.store.box<Site>();

Stream<List<Site>> get siteStream => siteBox.query().watch(triggerImmediately: true).map((q) => q.find());

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  void _showAddSiteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddSiteDialog(
        onSiteAdded: (site) {
          Navigator.of(context).pop();
          // The site is already saved in the dialog, no need to reload
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
              Navigator.of(context).pop();
              // No need to reload, the stream will automatically update
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          "Sites",
          style: TextStyle(
            color: Color(0xFF222B45),
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showAddSiteDialog,
            icon: const Icon(Icons.add, color: Color(0xFF2196F3)),
            tooltip: 'Add Site',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF8F9FF),  // Very light purple-blue
              Color(0xFFE8F4FD),  // Light blue
            ],
          ),
        ),
        child: StreamBuilder<List<Site>>(
          stream: siteStream,
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
                        color: const Color(0xFFE8F4FD),
                        borderRadius: BorderRadius.circular(60),
                      ),
                      child: const Icon(
                        Icons.location_on_outlined,
                        size: 60,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No sites yet',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222B45),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the + button to add your first site',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6C757D),
                      ),
                    ),
                  ],
                ),
              );
            }

            final sites = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
              child: ListView.builder(
                itemCount: sites.length,
                itemBuilder: (context, index) {
                  final site = sites[index];
                  return Container(
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
                          CircleAvatar(
                            backgroundColor: const Color(0xFF2196F3),
                            radius: 24,
                            child: Text(
                              site.name.isNotEmpty ? site.name[0].toUpperCase() : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  site.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Color(0xFF222B45),
                                  ),
                                ),
                                if (site.address != null && site.address!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
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
                                          site.address!,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (site.description != null && site.description!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    site.description!,
                                    style: const TextStyle(
                                      color: Color(0xFF6C757D),
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  'Created: ${_formatDate(site.createdAt)}',
                                  style: const TextStyle(
                                    color: Color(0xFF9E9E9E),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
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
            );
          },
        ),
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