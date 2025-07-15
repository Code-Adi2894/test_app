import 'package:flutter/material.dart';
import '../entities.dart'; // Make sure this imports your Task class

class TaskCompletionCheckbox extends StatelessWidget {
  final Task task;
  final ValueChanged<bool> onChanged;

  const TaskCompletionCheckbox({
    super.key,
    required this.task,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        title: Text('Mark as completed'),
        value: task.isCompleted,
        onChanged: (bool? newValue) {
          if (newValue != null) {
            onChanged(newValue);
          }
        },
        secondary: Icon(
          task.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
          color: task.isCompleted ? Colors.green : const Color(0xFF6C757D),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
