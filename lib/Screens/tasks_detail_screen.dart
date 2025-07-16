import 'package:flutter/material.dart';
import '../objectbox.g.dart';
import '../entities.dart';
import '../main.dart';
import '../services/user_service.dart';
import '../widgets/offline_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';


final taskBox = objectbox.store.box<Task>();
final taskImageBox = objectbox.store.box<TaskImage>();

// Stream to watch for changes to a specific task
Stream<Task?> getTaskStream(int taskId) {
  return taskBox.query(Task_.id.equals(taskId)).watch(triggerImmediately: true).map((query) {
    final tasks = query.find();
    return tasks.isNotEmpty ? tasks.first : null;
  });
}

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  late TextEditingController reviewNotesController;
  bool isCompleted = false;
  String priority = '';
  var levels = ["LOW", "MEDIUM", "HIGH"];
  bool _isOnline = true;
  bool _isSyncing = false;
  late final Connectivity _connectivity;
  File? imageFile;
  
  // New state variables for editing management
  bool _isEditing = false;
  Map<String, dynamic> _originalValues = {};
  Map<String, bool> _fieldModified = {
    'title': false,
    'description': false,
    'reviewNotes': false,
    'isCompleted': false,
    'priority': false,
  };
  Task? _lastProcessedTask;
  bool _isProcessingChanges = false;
  bool _hasShownUpdateNotification = false;


  @override
  void initState(){
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    descriptionController = TextEditingController(text: widget.task.description);
    reviewNotesController = TextEditingController(text: widget.task.reviewNotes);
    isCompleted = widget.task.isCompleted;
    priority = widget.task.priority;
    
    // Store original values for conflict resolution
    _storeOriginalValues();
    
    // Initialize connectivity
    _connectivity = Connectivity();
    _checkConnectivity();
    
    // Add listeners to track field modifications
    _addFieldListeners();
  }

  void _storeOriginalValues() {
    _originalValues = {
      'title': widget.task.title,
      'description': widget.task.description,
      'reviewNotes': widget.task.reviewNotes,
      'isCompleted': widget.task.isCompleted,
      'priority': widget.task.priority,
    };
  }

  void _addFieldListeners() {
    titleController.addListener(() {
      if (!_fieldModified['title']! && titleController.text != _originalValues['title']) {
        setState(() {
          _fieldModified['title'] = true;
          _isEditing = true;
        });
        _hasShownUpdateNotification = false; // Reset notification when user starts editing
      }
    });

    descriptionController.addListener(() {
      if (!_fieldModified['description']! && descriptionController.text != _originalValues['description']) {
        setState(() {
          _fieldModified['description'] = true;
          _isEditing = true;
        });
        _hasShownUpdateNotification = false; // Reset notification when user starts editing
      }
    });

    reviewNotesController.addListener(() {
      if (!_fieldModified['reviewNotes']! && reviewNotesController.text != _originalValues['reviewNotes']) {
        setState(() {
          _fieldModified['reviewNotes'] = true;
          _isEditing = true;
        });
        _hasShownUpdateNotification = false; // Reset notification when user starts editing
      }
    });
  }

  void _markFieldAsModified(String fieldName) {
    if (!_fieldModified[fieldName]!) {
      setState(() {
        _fieldModified[fieldName] = true;
        _isEditing = true;
      });
      _hasShownUpdateNotification = false; // Reset notification when user starts editing
    }
  }

  void _resetEditingState() {
    setState(() {
      _isEditing = false;
      _fieldModified = {
        'title': false,
        'description': false,
        'reviewNotes': false,
        'isCompleted': false,
        'priority': false,
      };
    });
    _storeOriginalValues();
    _hasShownUpdateNotification = false; // Reset notification flag
  }

  // Smart conflict resolution method
  void _handleIncomingChanges(Task incomingTask) {
    if (!_isEditing) {
      // If not editing, accept all changes
      _updateControllersFromTask(incomingTask);
      return;
    }

    print('\n🔄 HANDLING INCOMING CHANGES WHILE EDITING');
    _logTaskComparison(widget.task, incomingTask);

    // Check if there are any actual changes from another user
    bool hasChanges = incomingTask.title != widget.task.title ||
                     incomingTask.description != widget.task.description ||
                     incomingTask.reviewNotes != widget.task.reviewNotes ||
                     incomingTask.isCompleted != widget.task.isCompleted ||
                     incomingTask.priority != widget.task.priority ||
                     incomingTask.images.length != widget.task.images.length;

    // Show notification if there are changes and we haven't shown one yet
    if (hasChanges && !_hasShownUpdateNotification) {
      _showUpdateNotification(incomingTask);
      _hasShownUpdateNotification = true;
    }

    // Only update fields that haven't been modified by the user
    if (!_fieldModified['title']! && incomingTask.title != titleController.text) {
      print('✅ Updating title from "${titleController.text}" to "${incomingTask.title}"');
      titleController.text = incomingTask.title;
    }

    if (!_fieldModified['description']! && incomingTask.description != descriptionController.text) {
      print('✅ Updating description from "${descriptionController.text}" to "${incomingTask.description}"');
      descriptionController.text = incomingTask.description;
    }

    if (!_fieldModified['reviewNotes']! && incomingTask.reviewNotes != reviewNotesController.text) {
      print('✅ Updating review notes from "${reviewNotesController.text}" to "${incomingTask.reviewNotes}"');
      reviewNotesController.text = incomingTask.reviewNotes;
    }

    // Schedule state updates for after the build is complete
    bool needsStateUpdate = false;
    bool newIsCompleted = isCompleted;
    String newPriority = priority;

    if (!_fieldModified['isCompleted']! && incomingTask.isCompleted != isCompleted) {
      print('✅ Updating isCompleted from $isCompleted to ${incomingTask.isCompleted}');
      newIsCompleted = incomingTask.isCompleted;
      needsStateUpdate = true;
    }

    if (!_fieldModified['priority']! && incomingTask.priority != priority) {
      print('✅ Updating priority from "$priority" to "${incomingTask.priority}"');
      newPriority = incomingTask.priority;
      needsStateUpdate = true;
    }

    // Update other task properties that don't affect the form
    widget.task.updatedAt = incomingTask.updatedAt;
    widget.task.updatedBy = incomingTask.updatedBy;
    widget.task.isSynced = incomingTask.isSynced;
    
    // Update images if they've changed
    if (incomingTask.images.length != widget.task.images.length) {
      widget.task.images.clear();
      widget.task.images.addAll(incomingTask.images);
    }

    // Schedule state update after build is complete
    if (needsStateUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            isCompleted = newIsCompleted;
            priority = newPriority;
          });
        }
      });
    }
  }

  void _updateControllersFromTask(Task task) {
    titleController.text = task.title;
    descriptionController.text = task.description;
    reviewNotesController.text = task.reviewNotes;
    
    // Schedule state update after build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          isCompleted = task.isCompleted;
          priority = task.priority;
        });
      }
    });
  }

  void _showUpdateNotification(Task updatedTask) {
    // Show a toast notification about the update
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Task Updated',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${updatedTask.updatedBy} updated this task. Choose which changes to accept.',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2196F3),
        duration: const Duration(seconds: 6),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Review Changes',
          textColor: Colors.white,
          onPressed: () {
            _showConflictResolutionDialog(updatedTask);
          },
        ),
      ),
    );
  }

  void _showConflictResolutionDialog(Task updatedTask) {
    // Create a map to track which changes the user wants to accept
    Map<String, bool> acceptedChanges = {};
    
    // Initialize with all changes as accepted by default
    if (updatedTask.title != widget.task.title) acceptedChanges['title'] = true;
    if (updatedTask.description != widget.task.description) acceptedChanges['description'] = true;
    if (updatedTask.reviewNotes != widget.task.reviewNotes) acceptedChanges['reviewNotes'] = true;
    if (updatedTask.isCompleted != widget.task.isCompleted) acceptedChanges['isCompleted'] = true;
    if (updatedTask.priority != widget.task.priority) acceptedChanges['priority'] = true;
    if (updatedTask.images.length != widget.task.images.length) acceptedChanges['images'] = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Row(
                children: [
                  const Icon(Icons.merge_type, color: Color(0xFF2196F3)),
                  const SizedBox(width: 8),
                  const Text('Resolve Conflicts'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Updated by: ${updatedTask.updatedBy}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Time: ${updatedTask.updatedAt.toString().substring(0, 19)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6C757D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select which changes to accept:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildConflictResolutionList(updatedTask, acceptedChanges, setDialogState),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _applySelectedChanges(updatedTask, acceptedChanges);
                  },
                  child: const Text('Apply Selected'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConflictResolutionList(Task updatedTask, Map<String, bool> acceptedChanges, StateSetter setDialogState) {
    List<Widget> changes = [];
    
    if (updatedTask.title != widget.task.title) {
      changes.add(_buildConflictResolutionItem(
        'Title', 
        widget.task.title, 
        updatedTask.title, 
        acceptedChanges['title'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['title'] = value;
          });
        },
      ));
    }
    
    if (updatedTask.description != widget.task.description) {
      changes.add(_buildConflictResolutionItem(
        'Description', 
        widget.task.description, 
        updatedTask.description, 
        acceptedChanges['description'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['description'] = value;
          });
        },
      ));
    }
    
    if (updatedTask.reviewNotes != widget.task.reviewNotes) {
      changes.add(_buildConflictResolutionItem(
        'Review Notes', 
        widget.task.reviewNotes, 
        updatedTask.reviewNotes, 
        acceptedChanges['reviewNotes'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['reviewNotes'] = value;
          });
        },
      ));
    }
    
    if (updatedTask.isCompleted != widget.task.isCompleted) {
      changes.add(_buildConflictResolutionItem(
        'Completed', 
        widget.task.isCompleted.toString(), 
        updatedTask.isCompleted.toString(), 
        acceptedChanges['isCompleted'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['isCompleted'] = value;
          });
        },
      ));
    }
    
    if (updatedTask.priority != widget.task.priority) {
      changes.add(_buildConflictResolutionItem(
        'Priority', 
        widget.task.priority, 
        updatedTask.priority, 
        acceptedChanges['priority'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['priority'] = value;
          });
        },
      ));
    }
    
    if (updatedTask.images.length != widget.task.images.length) {
      changes.add(_buildConflictResolutionItem(
        'Images', 
        '${widget.task.images.length} images', 
        '${updatedTask.images.length} images', 
        acceptedChanges['images'] ?? false,
        (value) {
          setDialogState(() {
            acceptedChanges['images'] = value;
          });
        },
      ));
    }
    
    if (changes.isEmpty) {
      changes.add(const Text(
        'No conflicts detected',
        style: TextStyle(
          fontStyle: FontStyle.italic,
          color: Color(0xFF6C757D),
        ),
      ));
    }
    
    return Column(
      children: changes,
    );
  }

  Widget _buildConflictResolutionItem(String fieldName, String oldValue, String newValue, bool isAccepted, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isAccepted ? const Color(0xFFE8F5E8) : const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccepted ? const Color(0xFF28A745) : const Color(0xFFFFC107),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                value: isAccepted,
                onChanged: (value) => onChanged(value ?? false),
                activeColor: const Color(0xFF28A745),
              ),
              Expanded(
                child: Text(
                  fieldName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (isAccepted) ...[
            const SizedBox(height: 4),
            Text(
              'Will be updated to: $newValue',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF28A745),
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Current value: $oldValue',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6C757D),
              ),
            ),
            Text(
              'New value: $newValue',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFDC3545),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _applySelectedChanges(Task updatedTask, Map<String, bool> acceptedChanges) {
    print('\n🔄 APPLYING SELECTED CHANGES');
    
    // Apply only the selected changes
    if (acceptedChanges['title'] == true && !_fieldModified['title']!) {
      print('✅ Applying title change: "${widget.task.title}" → "${updatedTask.title}"');
      titleController.text = updatedTask.title;
    }
    
    if (acceptedChanges['description'] == true && !_fieldModified['description']!) {
      print('✅ Applying description change: "${widget.task.description}" → "${updatedTask.description}"');
      descriptionController.text = updatedTask.description;
    }
    
    if (acceptedChanges['reviewNotes'] == true && !_fieldModified['reviewNotes']!) {
      print('✅ Applying review notes change: "${widget.task.reviewNotes}" → "${updatedTask.reviewNotes}"');
      reviewNotesController.text = updatedTask.reviewNotes;
    }
    
    if (acceptedChanges['isCompleted'] == true && !_fieldModified['isCompleted']!) {
      print('✅ Applying isCompleted change: ${widget.task.isCompleted} → ${updatedTask.isCompleted}');
      setState(() {
        isCompleted = updatedTask.isCompleted;
      });
    }
    
    if (acceptedChanges['priority'] == true && !_fieldModified['priority']!) {
      print('✅ Applying priority change: "${widget.task.priority}" → "${updatedTask.priority}"');
      setState(() {
        priority = updatedTask.priority;
      });
    }
    
    if (acceptedChanges['images'] == true) {
      print('✅ Applying images change: ${widget.task.images.length} → ${updatedTask.images.length} images');
      widget.task.images.clear();
      widget.task.images.addAll(updatedTask.images);
    }
    
    // Update metadata
    widget.task.updatedAt = updatedTask.updatedAt;
    widget.task.updatedBy = updatedTask.updatedBy;
    widget.task.isSynced = updatedTask.isSynced;
    
    // Show confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${acceptedChanges.values.where((v) => v).length} changes'),
        backgroundColor: const Color(0xFF28A745),
        duration: const Duration(seconds: 2),
      ),
    );
  }



  void _handleBackPress() {
    if (_isEditing) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unsaved Changes'),
            content: const Text('You have unsaved changes. Are you sure you want to leave?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Leave'),
              ),
            ],
          );
        },
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    setState(() {
      _isOnline = result != ConnectivityResult.none;
    });
  }

  @override
  void dispose(){
    titleController.dispose();
    descriptionController.dispose();
    reviewNotesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    // Log the task before saving
    print('\n💾 SAVE OPERATION STARTED');
    _logTaskProperties('TASK BEFORE SAVE', widget.task);
    
    widget.task.title = titleController.text;
    widget.task.description = descriptionController.text;
    widget.task.reviewNotes = reviewNotesController.text;
    widget.task.isCompleted = isCompleted;
    widget.task.priority = priority;
    widget.task.updatedAt = DateTime.now();
    widget.task.updatedBy = userService.getCurrentUserEmail();
    widget.task.isSynced = false;

    try{
      taskBox.put(widget.task);
      
      // Reset editing state after successful save
      _resetEditingState();
      _lastProcessedTask = null; // Reset to allow processing new changes
      _hasShownUpdateNotification = false; // Reset notification flag
      
      // Log the task after saving
      print('\n✅ SAVE OPERATION COMPLETED');
      _logTaskProperties('TASK AFTER SAVE', widget.task);
      
      // Auto-sync if online
      if (_isOnline) {
        _syncTask();
      }
      
      Navigator.pop(context);
      print("Updated task");
    }catch(e){
      print("Error $e");
    }
  }

  void _syncTask() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      // Log the task before syncing
      print('\n🔄 SYNC OPERATION STARTED');
      _logTaskProperties('TASK TO SYNC', widget.task);
      
      final success = await syncService.syncTask(widget.task);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task synced successfully!'),
            backgroundColor: Color(0xFF28A745),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Sync operation failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: const Color(0xFFDC3545),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  // Helper method to get current task from database
  Task getCurrentTask() {
    final query = taskBox.query(Task_.id.equals(widget.task.id)).build();
    final tasks = query.find();
    query.close();
    return tasks.isNotEmpty ? tasks.first : widget.task;
  }



  // Helper method to log task properties
  void _logTaskProperties(String taskName, Task task) {
    print('=== $taskName Task Properties ===');
    print('ID: ${task.id}');
    print('Title: "${task.title}"');
    print('Description: "${task.description}"');
    print('Is Completed: ${task.isCompleted}');
    print('Is Synced: ${task.isSynced}');
    print('Priority: "${task.priority}"');
    print('Review Notes: "${task.reviewNotes}"');
    print('Updated At: ${task.updatedAt}');
    print('Updated By: "${task.updatedBy}"');
    print('Cases ID: ${task.cases.target?.id ?? "null"}');
    print('Images Count: ${task.images.length}');
    print('================================');
  }

  // Helper method to compare and log two tasks
  void _logTaskComparison(Task localTask, Task remoteTask) {
    print('\n🔍 TASK COMPARISON LOG 🔍');
    print('=' * 50);
    
    _logTaskProperties('LOCAL', localTask);
    print('');
    _logTaskProperties('REMOTE', remoteTask);
    print('');
    
    // Log differences
    print('📊 DIFFERENCES:');
    if (localTask.title != remoteTask.title) {
      print('❌ Title: Local="${localTask.title}" vs Remote="${remoteTask.title}"');
    }
    if (localTask.description != remoteTask.description) {
      print('❌ Description: Local="${localTask.description}" vs Remote="${remoteTask.description}"');
    }
    if (localTask.isCompleted != remoteTask.isCompleted) {
      print('❌ Completed: Local=${localTask.isCompleted} vs Remote=${remoteTask.isCompleted}');
    }
    if (localTask.priority != remoteTask.priority) {
      print('❌ Priority: Local="${localTask.priority}" vs Remote="${remoteTask.priority}"');
    }
    if (localTask.reviewNotes != remoteTask.reviewNotes) {
      print('❌ Review Notes: Local="${localTask.reviewNotes}" vs Remote="${remoteTask.reviewNotes}"');
    }
    if (localTask.isSynced != remoteTask.isSynced) {
      print('❌ Synced: Local=${localTask.isSynced} vs Remote=${remoteTask.isSynced}');
    }
    if (localTask.updatedAt != remoteTask.updatedAt) {
      print('❌ Updated At: Local=${localTask.updatedAt} vs Remote=${remoteTask.updatedAt}');
    }
    if (localTask.updatedBy != remoteTask.updatedBy) {
      print('❌ Updated By: Local="${localTask.updatedBy}" vs Remote="${remoteTask.updatedBy}"');
    }
    
    print('=' * 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => _handleBackPress(),
        ),
        title: StreamBuilder<Task?>(
          stream: getTaskStream(widget.task.id),
          builder: (context, snapshot) {
            final task = snapshot.data ?? widget.task;
            return Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_isEditing)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Editing',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          if (_isOnline)
            IconButton(
              onPressed: _isSyncing ? null : _syncTask,
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
              tooltip: 'Sync Task',
            ),
          IconButton(
            onPressed: _saveChanges,
            icon: const Icon(Icons.save, color: Colors.white),
            tooltip: 'Save Changes',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const OfflineIndicator(),
          Expanded(
            child: StreamBuilder<Task?>(
              stream: getTaskStream(widget.task.id),
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
                }

                final task = snapshot.data ?? widget.task;
                
                // Only process changes if we're not already processing and if this is a new task
                if (!_isProcessingChanges && (_lastProcessedTask == null || _lastProcessedTask!.updatedAt != task.updatedAt)) {
                  _isProcessingChanges = true;
                  
                  // Log local and remote tasks for debugging
                  _logTaskProperties('LOCAL (widget.task)', widget.task);
                  _logTaskProperties('REMOTE (from stream)', task);
                  
                  // Use smart conflict resolution instead of always updating
                  _handleIncomingChanges(task);
                  
                  // Mark this task as processed
                  _lastProcessedTask = task;
                  
                  // Reset processing flag after a short delay
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) {
                      setState(() {
                        _isProcessingChanges = false;
                      });
                    }
                  });
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task Details Card
                      Container(
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
                                          task.title,
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF495057),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Task Details',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6C757D),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: task.isSynced 
                                        ? const Color(0xFFE8F5E8) 
                                        : const Color(0xFFFFEBEE),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          task.isSynced ? Icons.check_circle : Icons.sync,
                                          size: 14,
                                          color: task.isSynced 
                                            ? const Color(0xFF28A745) 
                                            : const Color(0xFFDC3545),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.isSynced ? 'Synced' : 'Pending',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: task.isSynced 
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
                              Text(
                                task.description,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6C757D),
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                      fontSize: 12,
                                      color: Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ],
                              ),
                              if (task.updatedBy.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 12,
                                      color: const Color(0xFF9E9E9E),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'By: ${task.updatedBy}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF9E9E9E),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images Section
                      if(task.images.isNotEmpty)
                        Container(
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
                                    const Icon(
                                      Icons.photo_library,
                                      color: Color(0xFF2196F3),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Task Images',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF495057),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: task.images.length,
                                    itemBuilder: (context, index){
                                      final image = task.images[index];
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.memory(
                                            Uint8List.fromList(image.imageBytes),
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    }
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),

                      // Review Notes Section
                      if (task.reviewNotes.isNotEmpty) ...[
                        Container(
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
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Edit Section
                      Container(
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
                              const Text(
                                'Edit Task',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF495057),
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldModified['title']! 
                                    ? const Color(0xFFFFF3CD) 
                                    : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _fieldModified['title']! 
                                    ? Border.all(color: Colors.orange, width: 1)
                                    : null,
                                ),
                                child: TextField(
                                  controller: titleController,
                                  decoration: InputDecoration(
                                    labelText: 'Title',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(
                                      color: _fieldModified['title']! 
                                        ? Colors.orange 
                                        : const Color(0xFF6C757D)
                                    ),
                                    suffixIcon: _fieldModified['title']! 
                                      ? const Icon(Icons.edit, color: Colors.orange, size: 16)
                                      : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldModified['description']! 
                                    ? const Color(0xFFFFF3CD) 
                                    : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _fieldModified['description']! 
                                    ? Border.all(color: Colors.orange, width: 1)
                                    : null,
                                ),
                                child: TextField(
                                  controller: descriptionController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    labelText: 'Description',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(
                                      color: _fieldModified['description']! 
                                        ? Colors.orange 
                                        : const Color(0xFF6C757D)
                                    ),
                                    suffixIcon: _fieldModified['description']! 
                                      ? const Icon(Icons.edit, color: Colors.orange, size: 16)
                                      : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldModified['reviewNotes']! 
                                    ? const Color(0xFFFFF3CD) 
                                    : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _fieldModified['reviewNotes']! 
                                    ? Border.all(color: Colors.orange, width: 1)
                                    : null,
                                ),
                                child: TextField(
                                  controller: reviewNotesController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    labelText: 'Review Notes',
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    labelStyle: TextStyle(
                                      color: _fieldModified['reviewNotes']! 
                                        ? Colors.orange 
                                        : const Color(0xFF6C757D)
                                    ),
                                    hintText: 'Add review notes, comments, or observations...',
                                    hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                                    suffixIcon: _fieldModified['reviewNotes']! 
                                      ? const Icon(Icons.edit, color: Colors.orange, size: 16)
                                      : null,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldModified['isCompleted']! 
                                    ? const Color(0xFFFFF3CD) 
                                    : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: _fieldModified['isCompleted']! 
                                    ? Border.all(color: Colors.orange, width: 1)
                                    : null,
                                ),
                                padding: _fieldModified['isCompleted']! 
                                  ? const EdgeInsets.all(8)
                                  : EdgeInsets.zero,
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: isCompleted,
                                      onChanged: (bool? value){
                                        setState((){
                                          isCompleted = value ?? false;
                                        });
                                        _markFieldAsModified('isCompleted');
                                      },
                                      activeColor: const Color(0xFF28A745),
                                    ),
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Text(
                                            "Mark as completed",
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: _fieldModified['isCompleted']! 
                                                ? Colors.orange 
                                                : const Color(0xFF495057),
                                            ),
                                          ),
                                          if (_fieldModified['isCompleted']!)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 8),
                                              child: Icon(Icons.edit, color: Colors.orange, size: 16),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                decoration: BoxDecoration(
                                  color: _fieldModified['priority']! 
                                    ? const Color(0xFFFFF3CD) 
                                    : const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(12),
                                  border: _fieldModified['priority']! 
                                    ? Border.all(color: Colors.orange, width: 1)
                                    : null,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: DropdownButton<String>(
                                          value: priority,
                                          isExpanded: true,
                                          underline: Container(),
                                          icon: Icon(
                                            Icons.keyboard_arrow_down, 
                                            color: _fieldModified['priority']! 
                                              ? Colors.orange 
                                              : const Color(0xFF6C757D)
                                          ),
                                          items: levels.map((String level){
                                            return DropdownMenuItem<String>(
                                              value: level,
                                              child: Text(level),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue){
                                            setState((){
                                              priority = newValue!;
                                            });
                                            _markFieldAsModified('priority');
                                          },
                                        ),
                                      ),
                                      if (_fieldModified['priority']!)
                                        const Icon(Icons.edit, color: Colors.orange, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Upload Image Button
                              ElevatedButton(
                                onPressed: () async {
                                  final picker = ImagePicker();
                                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    final bytes = await pickedFile.readAsBytes();
                                    final taskImage = TaskImage(imageBytes: bytes);
                                    taskImage.task.target = task;

                                    final imageId = taskImageBox.put(taskImage);
                                    taskImage.id = imageId;
                                    setState(() {
                                      imageFile = File(pickedFile.path);
                                    });
                                    

                                    // Update task
                                    task.isSynced = false;
                                    task.updatedAt = DateTime.now();
                                    taskBox.put(task);
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Image uploaded successfully!'),
                                        backgroundColor: Color(0xFF28A745),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2196F3),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Upload Image"),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}