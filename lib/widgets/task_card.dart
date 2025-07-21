import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../Screens/tasks_detail_screen.dart';
import '../entities.dart';
import '../services/sync_service.dart';

class TaskCard extends StatelessWidget{
  final Task task;
  final void Function(Task) onSync;
  final isOnline;

  const TaskCard({super.key, required this.onSync, required this.task, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return (Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FC), // pastel card
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        title: Row(
          children: [
            Expanded(
              child: Text(
                task.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF495057),
                ),
              ),
            ),
            // Task sync status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: task.isSynced
                    ? const Color(0xFFE8F5E8)
                    : const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                task.isSynced ? Icons.check_circle : Icons.sync,
                size: 12,
                color: task.isSynced
                    ? const Color(0xFF28A745)
                    : const Color(0xFFDC3545),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              task.description,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6C757D)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Task metadata
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(task.priority),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  task.isCompleted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: task.isCompleted
                      ? Colors.green
                      : const Color(0xFF6C757D),
                  size: 16,
                ),
                const Spacer(),
                // Task sync button - only show when online
                if (isOnline)
                  IconButton(
                    onPressed: () => onSync(task),
                    icon: const Icon(
                      Icons.sync,
                      size: 16,
                      color: Color(0xFF2196F3),
                    ),
                    tooltip: 'Sync Task',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Last updated and updated by info
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 12,
                  color: const Color(0xFF9E9E9E),
                ),
                const SizedBox(width: 4),
                Text(
                  'Updated: ${task.updatedAt.toString().substring(0, 19)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(width: 16),
                if (task.updatedBy.isNotEmpty) ...[
                  Icon(Icons.person, size: 12, color: const Color(0xFF9E9E9E)),
                  const SizedBox(width: 4),
                  Text(
                    'By: ${task.updatedBy}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
      ),
    ));
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFDC3545);
      case 'MEDIUM':
        return const Color(0xFFFFC107);
      case 'LOW':
        return const Color(0xFF28A745);
      default:
        return const Color(0xFF6C757D);
    }
  }
}
