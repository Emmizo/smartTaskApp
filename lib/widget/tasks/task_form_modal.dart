import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/notification_service.dart';
import '../../pages/list_all_task.dart';
import '../../provider/all_task_provider.dart';
import '../../provider/theme_provider.dart';

class TaskFormModal extends StatefulWidget {
  final Map<dynamic, dynamic>? task;
  final ApiClient apiClient;
  final String? token;
  final Function(bool success) onTaskSaved;

  const TaskFormModal({
    super.key,
    this.task,
    required this.apiClient,
    this.token,
    required this.onTaskSaved,
  });

  @override
  State<TaskFormModal> createState() => _TaskFormModalState();
}

class _TaskFormModalState extends State<TaskFormModal> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _isSubmitting = false;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 0));
  int? _selectedStatusId;
  int? _selectedProjectId;
  List<dynamic> _availableUsers = [];
  List<dynamic> _availableProjects = [];
  Map<String, dynamic>? _selectedUser;
  List<int> selectedTagIds = [];
  List<dynamic> _tags = [];
  final List<Map<String, dynamic>> _statusOptions = [
    {'id': 1, 'name': 'Normal'},
    {'id': 2, 'name': 'Medium'},
    {'id': 3, 'name': 'High'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (mounted) {
      // Delay the fetch calls until after the build phase
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          fetchUsers();
          fetchProjects();
          fetchTags();
        }
      });
    }
  }

  Future<void> fetchUsers() async {
    try {
      final apiClient = ApiClient();
      final users = await apiClient.allUsers();
      if (mounted) {
        setState(() {
          _availableUsers = users;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching users: $e');
      }
    }
  }

  Future<void> fetchProjects() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');
      String? token = widget.token;

      if (token == null && userData != null && userData.isNotEmpty) {
        final List<dynamic> userDataMap = jsonDecode(userData);
        if (userDataMap.isNotEmpty && userDataMap[0]['token'] != null) {
          token = userDataMap[0]['token'].toString();
        }
      }

      if (token == null) {
        if (kDebugMode) {
          print('Error: No authentication token available');
        }
        return;
      }

      final projects = await widget.apiClient.getAllProjects(token);
      if (mounted) {
        setState(() {
          _availableProjects = projects;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching projects: $e');
      }
    }
  }

  Future<void> fetchTags() async {
    try {
      final apiClient = ApiClient();
      final tags = await apiClient.taskTags();

      if (mounted) {
        setState(() {
          _tags = tags;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tags: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();

    // If editing, populate form fields
    if (widget.task != null) {
      _titleController.text = widget.task!['title'] ?? '';
      _projectNameController.text = widget.task!['project_name'] ?? '';
      _selectedProjectId = widget.task!['project_id'];
      _descriptionController.text = widget.task!['description'] ?? '';

      // Handle date
      if (widget.task!['due_date'] != null) {
        try {
          _selectedDate = DateTime.parse(widget.task!['due_date']);
          _dueDateController.text = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(_selectedDate);
          // ignore: empty_catches
        } catch (e) {}
      }

      if (widget.task!['status_id'] != null) {
        _selectedStatusId = widget.task!['status_id'];
      }
      if (widget.task!['tags'] != null && widget.task!['tags'] is List) {
        final List<dynamic> taskTags = widget.task!['tags'];

        selectedTagIds = taskTags.map<int>((tag) => tag['id'] as int).toList();
      }
      // Handle assigned user
      if (widget.task!['user_id'] != null) {
        // Find the user in available users
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await fetchUsers(); // Ensure users are loaded first
          if (mounted && _availableUsers.isNotEmpty) {
            final user = _availableUsers.firstWhere(
              (user) => user['id'] == widget.task!['user_id'],
              orElse: () => null,
            );
            if (user != null) {
              setState(() {
                _selectedUser = user;
              });
            }
          }
        });
      }
    } else {
      // Set default due date for new tasks
      _dueDateController.text = DateFormat('MMM d, yyyy').format(_selectedDate);
      _selectedStatusId = 2; // Default to Medium priority
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _projectNameController.dispose();
    _dueDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Show date and time picker

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year, now.month, now.day);
    final initialDate =
        _selectedDate.isBefore(firstDate) ? firstDate : _selectedDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: firstDate.add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      if (pickedTime != null) {
        final DateTime newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          _selectedDate = newDateTime;
          _dueDateController.text = DateFormat(
            'MMM d, yyyy hh:mm a',
          ).format(_selectedDate);
        });
      }
    }
  }

  // Select a user
  void _selectUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUser = user;
    });
  }

  // Clear the selected user
  void _clearUser() {
    setState(() {
      _selectedUser = null;
    });
  }

  // Select a project (for create task only)
  void _selectProject(int projectId, String projectName) {
    setState(() {
      _selectedProjectId = projectId;
      _projectNameController.text = projectName;
    });
  }

  Future<void> _showUpdateConfirmation(Map<String, dynamic> response) async {
    if (!mounted) return;

    String projectName = _projectNameController.text;
    if (projectName.isEmpty && _availableProjects.isNotEmpty) {
      final project = _availableProjects.firstWhere(
        (p) => p['id'] == _selectedProjectId,
        orElse: () => {'name': 'Unknown Project'},
      );
      projectName = project['name'];
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Updated Successfully'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Title: ${_titleController.text}'),
              const SizedBox(height: 8),
              Text('Project: $projectName'),
              const SizedBox(height: 8),
              Text(
                'Due Date: ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
              ),
              const SizedBox(height: 16),
              const Text('Would you like to notify the assigned user?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send Notification'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      // Send notification to the assigned user
      await NotificationService().showTaskCreatedNotification(
        'Updated',
        projectName,
        response['projectId']?.toString() ?? '',
        _titleController.text,
        response['userIds'] as List<String>? ?? [],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final taskData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'due_date': _selectedDate.toIso8601String(),
        'user_id':
            _selectedUser != null
                ? int.parse(_selectedUser!['id'].toString())
                : null,
        'tag_id[]': selectedTagIds.isNotEmpty ? selectedTagIds.join(',') : '',
        'project_id': _selectedProjectId,
        'status_id': _selectedStatusId,
      };

      Map<String, dynamic> response;
      final isEditing = widget.task != null;

      // Get token from widget or SharedPreferences
      String? token = widget.token;
      if (token == null) {
        final prefs = await SharedPreferences.getInstance();
        final String? userData = prefs.getString('userData');
        if (userData != null && userData.isNotEmpty) {
          final List<dynamic> userDataMap = jsonDecode(userData);
          if (userDataMap.isNotEmpty && userDataMap[0]['token'] != null) {
            token = userDataMap[0]['token'].toString();
          }
        }
      }

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      if (isEditing) {
        response = await widget.apiClient.updateTask(
          widget.task!['id'].toString(),
          taskData,
        );
      } else {
        response = await widget.apiClient.createTask(taskData);
      }

      if (!mounted) return;

      if (response['status'] == 200) {
        // Get project name for notification
        String projectName = _projectNameController.text;
        if (projectName.isEmpty && _availableProjects.isNotEmpty) {
          final project = _availableProjects.firstWhere(
            (p) => p['id'] == _selectedProjectId,
            orElse: () => {'name': 'Unknown Project'},
          );
          projectName = project['name'];
        }

        // Schedule reminder notifications
        if (_selectedUser != null) {
          final taskId =
              isEditing
                  ? widget.task!['id'].toString()
                  : response['taskId']?.toString() ?? '';
          if (taskId.isNotEmpty) {
            await NotificationService().scheduleTaskDeadlineReminder(
              taskId,
              _titleController.text,
              projectName,
              _selectedProjectId?.toString() ?? '',
              _selectedDate,
              _selectedUser!['id'].toString(),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Task ${isEditing ? 'updated' : 'created'} successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }

        // For updates, show confirmation dialog before notification
        if (isEditing) {
          if (!mounted) return;
          await _showUpdateConfirmation(response);
        } else {
          try {
            final List<String> userIds = [];
            if (_selectedUser != null && _selectedUser!['id'] != null) {
              userIds.add(_selectedUser!['id'].toString());

              await NotificationService().showTaskCreatedNotification(
                'Created',
                projectName,
                _selectedProjectId?.toString() ?? '',
                _titleController.text,
                userIds,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification sent successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            }
          } catch (e) {
            print('Notification error: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to send notification: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          }
        }

        if (mounted) {
          await context.read<AllTaskProvider>().fetchAllTasks();
          Navigator.pop(context);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ListAllTask()),
          );
        }
        widget.onTaskSaved(true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                response['error'] ??
                    'Failed to ${isEditing ? 'update' : 'create'} task',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Submit error: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isEditing = widget.task != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: themeProvider.getAdaptiveCardColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        isEditing ? 'Edit Task' : 'Create New Task',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Project field - Different behavior for create vs update
                if (isEditing)
                  // In Edit mode: Project name is read-only
                  TextFormField(
                    controller: _projectNameController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Project Name',
                      border: OutlineInputBorder(),
                    ),
                  )
                else
                  // In Create mode: Project is a dropdown selection
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _selectedProjectId,
                        decoration: const InputDecoration(
                          labelText: 'Select Project',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select a project'),
                        items:
                            _availableProjects.map((project) {
                              return DropdownMenuItem<int>(
                                value: project['id'],
                                child: Text(project['name']),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final projectName =
                                _availableProjects.firstWhere(
                                  (p) => p['id'] == value,
                                )['name'];
                            _selectProject(value, projectName);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a project';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Due date field
                TextFormField(
                  controller: _dueDateController,
                  readOnly: true,
                  onTap: _selectDate,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please select a due date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Status/Priority dropdown
                DropdownButtonFormField<int>(
                  value: _selectedStatusId,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _statusOptions.map((status) {
                        // Determine color based on status
                        Color statusColor;
                        switch (status['id']) {
                          case 1:
                            statusColor = Colors.green;
                            break;
                          case 2:
                            statusColor = Colors.orange;
                            break;
                          case 3:
                            statusColor = Colors.red;
                            break;
                          default:
                            statusColor = Colors.blue;
                        }

                        return DropdownMenuItem<int>(
                          value: status['id'],
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(status['name']),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedStatusId = value;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a priority';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // User selection field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Assigned User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Display selected user in a Chip, keeping the same functionality
                    if (_selectedUser != null)
                      Chip(
                        label: Text(
                          '${_selectedUser!['first_name']} ${_selectedUser!['last_name']}',
                        ),
                        onDeleted: _clearUser,
                      ),
                    const SizedBox(height: 8),
                    // Searchable dropdown for available users, styled similarly to DropdownButtonFormField
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SearchAnchor(
                        builder: (
                          BuildContext context,
                          SearchController controller,
                        ) {
                          return GestureDetector(
                            onTap: () {
                              controller.openView();
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      controller.text.isEmpty
                                          ? 'Search and select a user'
                                          : controller.text,
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        suggestionsBuilder: (
                          BuildContext context,
                          SearchController controller,
                        ) {
                          return _availableUsers
                              .where((user) {
                                final fullName =
                                    '${user['first_name']} ${user['last_name']}';
                                return fullName.toLowerCase().contains(
                                  controller.text.toLowerCase(),
                                );
                              })
                              .map((user) {
                                return ListTile(
                                  title: Text(
                                    '${user['first_name']} ${user['last_name']}',
                                  ),
                                  subtitle: Text(user['email'] ?? ''),
                                  onTap: () {
                                    _selectUser(user);
                                    controller.closeView(
                                      '${user['first_name']} ${user['last_name']}',
                                    );
                                  },
                                );
                              })
                              .toList();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Tag selection
                const Text(
                  'Select Tags',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8.0),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    hintText: 'Select tags',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: themeProvider.getAdaptiveCardColor(context),
                  ),
                  items:
                      _tags.isNotEmpty
                          ? _tags.map((tag) {
                            return DropdownMenuItem<int>(
                              value: tag['id'] as int?,
                              child: Text(tag['tag_name']?.toString() ?? ''),
                            );
                          }).toList()
                          : [],
                  onChanged: (value) {
                    if (value != null && !selectedTagIds.contains(value)) {
                      setState(() {
                        selectedTagIds.add(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children:
                      selectedTagIds.map((id) {
                        final tag = _tags.firstWhere(
                          (t) => t['id'] == id,
                          orElse: () => {'id': id, 'tag_name': 'Unknown Tag'},
                        );
                        return Chip(
                          label: Text(
                            tag['tag_name']?.toString() ?? 'Unknown Tag',
                          ),
                          onDeleted: () {
                            setState(() {
                              selectedTagIds.remove(id);
                            });
                          },
                        );
                      }).toList(),
                ),
                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B4EFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isSubmitting
                            ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            )
                            : Text(isEditing ? 'Update Task' : 'Create Task'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
