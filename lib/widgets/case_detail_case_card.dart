import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../entities.dart';

class CaseDetailCaseCard extends StatelessWidget {
  final Cases cases;

  CaseDetailCaseCard({super.key, required this.cases});

  @override
  Widget build(BuildContext context) {
    return // Case Details Card
    Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cases.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF495057),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Text(
                      //   'Case Details',
                      //   style: const TextStyle(
                      //     fontSize: 14,
                      //     color: Color(0xFF6C757D),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Sync status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cases.isSynced
                        ? const Color(0xFFE8F5E8)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        cases.isSynced ? Icons.check_circle : Icons.sync,
                        size: 14,
                        color: cases.isSynced
                            ? const Color(0xFF28A745)
                            : const Color(0xFFDC3545),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        cases.isSynced ? 'Synced' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cases.isSynced
                              ? const Color(0xFF28A745)
                              : const Color(0xFFDC3545),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cases.description != null &&
                cases.description!.isNotEmpty)
              Text(
                cases.description!,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
              ),
            const SizedBox(height: 8),
            if (cases.isSynced)
              Text(
                'Last synced: ${cases.lastSyncedAt?.toString().substring(0, 19) ?? 'Never'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
              ),
          ],
        ),
      ),
    );
  }
}
