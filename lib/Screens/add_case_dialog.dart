import 'package:flutter/material.dart';
import '../entities.dart';
import '../services/site_service.dart';
import '../main.dart';
import '../objectbox.g.dart';

class AddCaseDialog extends StatefulWidget {
  final Function(Cases) onCaseAdded;

  const AddCaseDialog({
    super.key,
    required this.onCaseAdded,
  });

  @override
  State<AddCaseDialog> createState() => _AddCaseDialogState();
}

class _AddCaseDialogState extends State<AddCaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedSiteId;
  List<Map<String, dynamic>> _sites = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSites();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadSites() {
    setState(() {
      _sites = siteService.getSitesForDropdown();
    });
  }

  void _addCase() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get the selected site
      final selectedSite = siteService.getSiteById(_selectedSiteId!);
      if (selectedSite == null) {
        throw Exception('Selected site not found');
      }

      // Create new case
      final newCase = Cases(
        name: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        isSynced: false,
        syncStatus: 'pending',
      );

      // Set the site relationship
      newCase.site.target = selectedSite;

      // Save the case
      final caseId = objectbox.store.box<Cases>().put(newCase);
      newCase.id = caseId;

      widget.onCaseAdded(newCase);
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.folder_open,
                    color: Color(0xFF2196F3),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add New Case',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Site Selection Dropdown
              DropdownButtonFormField<int>(
                value: _selectedSiteId,
                decoration: InputDecoration(
                  labelText: 'Select Site *',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: _sites.map((site) {
                  return DropdownMenuItem<int>(
                    value: site['id'] as int,
                    child: Text(site['name'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSiteId = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a site';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Case Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Case Title *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a case title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: const Icon(Icons.description_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Add Button
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addCase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Add Case'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 