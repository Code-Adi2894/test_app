import 'package:flutter/material.dart';
import '../entities.dart';
import '../services/sync_service.dart';

class TaskCard extends StatefulWidget{
  final Task task;
  final bool isOnline;
  const TaskCard({super.key, required this.task, required this.isOnline});

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late bool _isCompleted;

  @override
  void initState() {
    super.initState();
    _isCompleted = widget.task.isCompleted;
  }

  void _syncTask(Task task) async {
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.task.title, style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    )),
                    Text(widget.task.description, style: const TextStyle(
                      fontSize: 16,
                    ))
                  ],
                ),
                Spacer(),
                Icon(
                  widget.task.isSynced ? Icons.check_circle : Icons.sync,
                  size: 12,
                  color: widget.task.isSynced
                    ? const Color(0xFF28A745)
                    : const Color(0xFFDC3545),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(widget.task.priority).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.task.priority,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getPriorityColor(widget.task.priority),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ),
                Spacer(),
                if (widget.isOnline)
                    IconButton(
                      onPressed: () => _syncTask(widget.task),
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
            CheckboxListTile(
              title: const Text('Mark as completed'),
              value: _isCompleted,
              onChanged: (bool? newValue) {
                if (newValue != null) {
                  setState(() {
                    _isCompleted = newValue;
                    widget.task.isCompleted = newValue;
                  });
                }
              },
              secondary: Icon(
                _isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: _isCompleted ? Colors.green : const Color(0xFF6C757D),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: const Color(0xFF9E9E9E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updated: ${widget.task.updatedAt.toString().substring(0, 19)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (widget.task.updatedBy.isNotEmpty) ...[
                    Icon(
                      Icons.person,
                      size: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'By: ${widget.task.updatedBy}',
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
      ),
    );


  }
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