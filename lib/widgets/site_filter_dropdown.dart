// lib/widgets/site_filter_dropdown.dart

import 'package:flutter/material.dart';
import '../entities.dart';
import '../main.dart';

final siteBox = objectbox.store.box<Site>();
Stream<List<Site>> get siteStream =>
    siteBox.query().watch(triggerImmediately: true).map((q) => q.find());

class SiteFilterDropdown extends StatelessWidget {
  final String? selectedSite;
  final ValueChanged<String?> onSiteChanged;

  const SiteFilterDropdown({
    Key? key,
    required this.selectedSite,
    required this.onSiteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Site>>(
      stream: siteStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data;
        if (items == null || items.isEmpty) {
          return const Center(
            child: Text(
              'No sites available',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: DropdownButtonFormField<String>(
            value: selectedSite,
            decoration: InputDecoration(
              labelText: 'Filter by Site',
              hintText: 'Select a site',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Theme.of(context).colorScheme.primary,
            ),
            isExpanded: true,
            items: items.map((site) {
              return DropdownMenuItem(
                value: site.name,
                child: Text(site.name, style: const TextStyle(fontSize: 16)),
              );
            }).toList(),
            onChanged: onSiteChanged,
          ),
        );
      },
    );
  }
}
