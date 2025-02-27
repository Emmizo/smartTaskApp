import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/notification_service.dart';
import 'package:smart_task_app/provider/get_task_tag_provider.dart';
import 'package:smart_task_app/provider/get_user_provider.dart';
import 'package:smart_task_app/widget/cartLoading.dart'; // Import your ApiClient

class ListAllTask extends StatefulWidget {
  const ListAllTask({super.key});

  @override
  State<ListAllTask> createState() => _ListAllTaskState();
}

class _ListAllTaskState extends State<ListAllTask> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _allTasks = [];
  List<dynamic> _filteredTasks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late ApiClient _apiClient;
  String? _userToken;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Function to fetch tasks from the API
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userData = prefs.getString('userData');

      if (userData != null && userData.isNotEmpty) {
        List<dynamic> userDataMap = jsonDecode(userData);
        _userToken = userDataMap[0]['token'];

        if (_userToken != null) {
          final response = await _apiClient.allTasks(_userToken!);
          setState(() {
            _allTasks = response;
            _filteredTasks = response;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print("Error fetching tasks: $e");
    }

    setState(() {
      _allTasks = [];
      _filteredTasks = [];
      _isLoading = false;
    });
  }

  Future<void> _performTaskDeletion(dynamic taskId) async {
    // Guard clause for null taskId
    if (taskId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Task ID is missing'),
          backgroundColor: Colors.red.shade300,
        ),
      );
      return;
    }

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(child: Text('Deleting task...')),
        backgroundColor: Colors.blue.shade300,
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Call the existing deleteTask method
      ApiClient apiClient = ApiClient();
      // Make sure your API client is properly handling the response
      await apiClient.deleteTask(taskId);

      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 10),
                Text('Success'),
              ],
            ),
            content: Text('Task deleted successfully!'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog

                  // Refresh the current page instead of pushing a new one
                  setState(() {
                    // This will trigger a rebuild of the widget
                    // You might also want to refetch the tasks here
                  });

                  // Alternative approach: navigate to the task list screen
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ListAllTask(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Hide the loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Show error message with more details
      print('Error deleting task: $e'); // Log the error for debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deletion failed: ${e.toString()}'),
          backgroundColor: Colors.red.shade300,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  // Filter tasks based on search query
  void _filterTasks(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredTasks = _allTasks;
      } else {
        _filteredTasks =
            _allTasks.where((task) {
              // Search in title
              final title = task['title'].toString().toLowerCase();
              if (title.contains(_searchQuery)) return true;

              // Search in project name
              final projectName = task['project_name'].toString().toLowerCase();
              if (projectName.contains(_searchQuery)) return true;

              // Search in status (priority)
              final status = task['status'].toString().toLowerCase();
              if (status.contains(_searchQuery)) return true;

              // Search in date
              final dueDate = task['due_date'] as String;
              try {
                final DateTime parsedDate = DateTime.parse(dueDate);
                final String formattedDate =
                    DateFormat('MMM d, yyyy').format(parsedDate).toLowerCase();
                if (formattedDate.contains(_searchQuery)) return true;

                // Allow searching by month name
                final String monthName =
                    DateFormat('MMMM').format(parsedDate).toLowerCase();
                if (monthName.contains(_searchQuery)) return true;

                // Allow searching by day or year
                final String day = DateFormat('d').format(parsedDate);
                final String year = DateFormat('yyyy').format(parsedDate);
                if (day == _searchQuery || year == _searchQuery) return true;
              } catch (e) {
                // Skip date search if date is invalid
              }

              // Search in tags
              final tags = task['tags'] as List<dynamic>;
              for (final tagObj in tags) {
                final tagName = tagObj['tag_name'].toString().toLowerCase();
                if (tagName.contains(_searchQuery)) return true;
              }

              return false;
            }).toList();
      }
    });
  }

  // Create or edit task
  Future<void> _showTaskForm({Map<dynamic, dynamic>? task}) async {
    final bool isEditing = task != null;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TaskFormModal(
            task: task,
            apiClient: _apiClient,
            token: _userToken!,
            onTaskSaved: (bool success) {
              if (success) {
                _loadTasks(); // Reload tasks after create/update
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Task ${isEditing ? 'updated' : 'created'} successfully',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
    );
  }

  Future<void> _showTaskDelete({Map<dynamic, dynamic>? task}) async {
    
    if (task == null || task['id'] == null) {
      return; 
    }

    
    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 10),
              Text('Warning'),
            ],
          ),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); 
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); 
                _performTaskDeletion(task['id']);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Tasks'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search name, priority, date, tags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon:
                      _searchQuery.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filterTasks('');
                            },
                          )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: _filterTasks,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        backgroundColor: const Color(0xFF6B4EFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body:
          _isLoading
              ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4, // Show 4 loading cards
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  return const CardLoading(
                    width: double.infinity,
                    height: 100,
                    margin: EdgeInsets.only(bottom: 16),
                  );
                },
              )
              : _filteredTasks.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No tasks available'
                            : 'No tasks found for "$_searchQuery"',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
              : ListView.builder(
                itemCount: _filteredTasks.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final task = _filteredTasks[index];
                  final title = task['title'] as String;
                  final projectName = task['project_name'] as String;
                  final dueDate = task['due_date'] as String;
                  final team = task['team'] as List<dynamic>;
                  final status = task['status'] as String;
                  final tags = task['tags'] as List<dynamic>;

                  // Calculate progress (dummy logic for demonstration)
                  final progress = 0.1 + (index * 0.3) % 0.9;

                  return TaskCard(
                    task: task,
                    title: title,
                    projectName: projectName,
                    dueDate: dueDate,
                    progress: progress,
                    team: team,
                    status: status,
                    tags: tags,
                    searchQuery: _searchQuery,
                    onEdit: () => _showTaskForm(task: task),
                    onDelete: () => _showTaskDelete(task: task),
                  );
                },
              ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final Map<dynamic, dynamic> task;
  final String title;
  final String projectName;
  final String dueDate;
  final double progress;
  final String status;
  final List<dynamic> team;
  final List<dynamic> tags;
  final String searchQuery;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const TaskCard({
    super.key,
    required this.task,
    required this.title,
    required this.projectName,
    required this.dueDate,
    required this.progress,
    required this.team,
    required this.status,
    required this.tags,
    required this.onEdit,
    required this.onDelete,

    this.searchQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    // Format due date
    final DateTime parsedDate = DateTime.parse(dueDate);
    final String formattedDate = DateFormat('MMM d, yyyy').format(parsedDate);

    // Status color based on priority
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'high':
        statusColor = Colors.red;
        break;
      case 'medium':
        statusColor = Colors.orange;
        break;
      case 'low':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B4EFF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Color(0xFF6B4EFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child:
                              searchQuery.isNotEmpty
                                  ? _highlightText(title, searchQuery)
                                  : Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child:
                              searchQuery.isNotEmpty
                                  ? _highlightText(
                                    status,
                                    searchQuery,
                                    baseStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  )
                                  : Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    searchQuery.isNotEmpty
                        ? _highlightText(
                          'Project: $projectName • Due: $formattedDate',
                          searchQuery,
                          baseStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        )
                        : Text(
                          'Project: $projectName • Due: $formattedDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Team avatars (showing up to 3)
                        ...buildTeamAvatars().take(3),

                        const SizedBox(width: 8),

                        // Tags
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: buildTags()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF6B4EFF),
                          ),
                        ),
                        // Centered Text
                        Center(
                          child: Text(
                            '${(progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, color: Color(0xFF6B4EFF)),
                        iconSize: 20,
                        tooltip: 'Edit Task',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete,
                          color: Color.fromARGB(255, 240, 56, 1),
                        ),
                        iconSize: 20,
                        tooltip: 'Delete Task',
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _highlightText(String text, String query, {TextStyle? baseStyle}) {
    if (query.isEmpty) {
      return Text(
        text,
        style:
            baseStyle ??
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final TextStyle defaultStyle =
        baseStyle ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
    final TextStyle highlightStyle = defaultStyle.copyWith(
      backgroundColor: Colors.yellow.withOpacity(0.3),
      fontWeight: FontWeight.w700,
    );

    final List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    final String lowercaseQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowercaseText.indexOf(lowercaseQuery, start);
      if (index == -1) {
        // No more matches
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start), style: defaultStyle));
        }
        break;
      }

      if (index > start) {
        spans.add(
          TextSpan(text: text.substring(start, index), style: defaultStyle),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + query.length),
          style: highlightStyle,
        ),
      );

      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> buildTeamAvatars() {
    List<Widget> avatars = [];

    for (int i = 0; i < team.length; i++) {
      final member = team[i];
      final profilePicture =
          member['profile_picture'] != null
              ? member['profile_picture'] as String
              : '';
      final firstName = member['first_name'] as String;
      final lastName = member['last_name'] as String;

      avatars.add(
        Tooltip(
          message: '$firstName $lastName',
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            child:
                profilePicture.isNotEmpty
                    ? CircleAvatar(
                      radius: 12,
                      backgroundImage: NetworkImage(profilePicture),
                    )
                    : CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.grey[400],
                      child: Text(
                        firstName[0] + lastName[0],
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
          ),
        ),
      );
    }

    return avatars;
  }

  List<Widget> buildTags() {
    List<Widget> tagWidgets = [];

    for (final tagObj in tags) {
      // Extract the tag name from the tag object
      final String tagName = tagObj['tag_name'] as String;

      tagWidgets.add(
        Container(
          margin: const EdgeInsets.only(right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child:
              searchQuery.isNotEmpty
                  ? _highlightText(
                    tagName,
                    searchQuery,
                    baseStyle: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  )
                  : Text(
                    tagName,
                    style: TextStyle(fontSize: 10, color: Colors.grey[700]),
                  ),
        ),
      );
    }

    return tagWidgets;
  }
}

class TaskFormModal extends StatefulWidget {
  final Map<dynamic, dynamic>? task;
  final ApiClient apiClient;
  final String token;
  final Function(bool success) onTaskSaved;

  const TaskFormModal({
    super.key,
    this.task,
    required this.apiClient,
    required this.token,
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
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  int? _selectedStatusId;
  int? _selectedProjectId;
  List<dynamic> _availableUsers = [];
  List<dynamic> _availableProjects = [];
  Map<String, dynamic>? _selectedUser;
  List<int> _selectedTagIds = [];
  List<dynamic> _tags = [];
  final List<Map<String, dynamic>> _statusOptions = [
    {'id': 1, 'name': 'Normal'},
    {'id': 2, 'name': 'Medium'},
    {'id': 3, 'name': 'High'},
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Delay the fetch calls until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsers();
      fetchProjects();
      fetchTags();
    });
  }

  Future<void> fetchUsers() async {
    final getUserProvider = Provider.of<GetUserProvider>(
      context,
      listen: false,
    );
    await getUserProvider.fetchUsers();

    // Update the UI with fetched users
    if (getUserProvider.users.isNotEmpty) {
      setState(() {
        _availableUsers = getUserProvider.users.first['data'] as List<dynamic>;
      });
    }
  }

  Future<void> fetchProjects() async {
    try {
      // You'll need to implement this method in your ApiClient
      final response = await widget.apiClient.getAllProjects(widget.token);
      setState(() {
        _availableProjects = response;
      });
    } catch (e) {
      print("Error fetching projects: $e");
    }
  }

  Future<void> fetchTags() async {
    final getTagProvider = Provider.of<GetTaskTagProvider>(
      context,
      listen: false,
    );
    await getTagProvider.fetchTags();

    // Update the UI with fetched users
    if (getTagProvider.tags.isNotEmpty) {
      setState(() {
        _tags = getTagProvider.tags.first['data'] as List<dynamic>;
      });
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

      // Handle date
      if (widget.task!['due_date'] != null) {
        try {
          _selectedDate = DateTime.parse(widget.task!['due_date']);
          _dueDateController.text = DateFormat(
            'yyyy-MM-dd HH:mm:ss',
          ).format(_selectedDate);
        } catch (e) {
          print('Error parsing date: $e');
        }
      }

      if (widget.task!['status_id'] != null) {
        _selectedStatusId = widget.task!['status_id'];
      }
      /* if (widget.task!['tags'] != null && widget.task!['tags'] is List) {
        List<dynamic> taskTags = widget.task!['tags'];
        _selectedTagIds = taskTags.map<int>((tag) => tag['id'] as int).toList();
      } */
      // Handle assigned user
      if (widget.task!['user_id'] != null) {
        // Find the user in available users
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_availableUsers.isNotEmpty) {
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

  // Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dueDateController.text = DateFormat(
          'MMM d, yyyy',
        ).format(_selectedDate);
      });
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

  // Main submit form handler that delegates to specific handlers
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      bool success = false;

      if (widget.task != null) {
        final result = await _handleUpdateTask();

        success = _isSuccessResponse(result);
      } else {
        final result = await _handleCreateTask();

        success = _isSuccessResponse(result);
      }

      if (success) {
        print("✅ Task successfully created/updated!");
        print(success);
        widget.onTaskSaved(true);

        if (mounted) {
          // First show the success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Task created/updated successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1), // Shorter duration
            ),
          );

          // Then show dialog
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 10),
                    Text('Success'),
                  ],
                ),
                content: Text('Task created successfully!'),
                actions: [
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      // Show notification after dialog is dismissed
                      NotificationService().showTaskCreatedNotification(
                        widget.task != null ? 'Updated' : 'Created',
                        _projectNameController.text,
                        _titleController.text,
                      );

                      Navigator.of(context).pop(); // Close dialog
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListAllTask(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save task. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        widget.onTaskSaved(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      widget.onTaskSaved(false);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  bool _isSuccessResponse(dynamic response) {
    if (response is bool) {
      return response;
    } else if (response is String) {
      // Handle string responses - you might need to adjust this based on your API's
      // response format. This assumes "success" or "true" in the response indicates success
      return response.toLowerCase().contains('success') ||
          response.toLowerCase() == 'true';
    } else if (response is Map) {
      // Handle map/json responses
      return response['success'] == true || response['status'] == 'success';
    }
    return false;
  }

  // Dedicated handler for updating an existing task
  Future<dynamic> _handleUpdateTask() async {
    print("🟡 Updating existing task...");

    final String taskId = widget.task!['id'].toString();
    final String title = _titleController.text;
    final DateTime deadline = _selectedDate;
    final List<int> userIds =
        _selectedUser != null
            ? [int.parse(_selectedUser!['id'].toString())]
            : [];
    final int projectId = _selectedProjectId!;
    final int statusId = _selectedStatusId!;

    return await widget.apiClient.updateTask(
      taskId,
      title,
      _descriptionController.text,
      deadline,
      userIds,
      _selectedTagIds,
      projectId,
      statusId,
      widget.token,
    );
  }

  // Dedicated handler for creating a new task
  Future<dynamic> _handleCreateTask() async {
   
    if (_selectedProjectId == null || _selectedStatusId == null) {
     
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project and status'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    final String title = _titleController.text;
    final DateTime deadline = _selectedDate;
    final List<int> userIds =
        _selectedUser != null
            ? [int.parse(_selectedUser!['id'].toString())]
            : [];
    final int projectId = _selectedProjectId!;
    final int statusId = _selectedStatusId!;

    print(
      "📤 Sending request: title=$title, deadline=$deadline, project_id=$projectId, status_id=$statusId",
    );

    try {
      final response = await widget.apiClient.createTask(
        title,
        _descriptionController.text,
        deadline,
        userIds,
        _selectedTagIds,
        projectId,
        statusId,
        widget.token,
      );


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      return true;
    } catch (e) {
     
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
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
                                      style: TextStyle(color: Colors.black),
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
                Text(
                  'Select Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8.0),
                DropdownButtonFormField<int>(
                  decoration: InputDecoration(
                    hintText: 'Select tags',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.blueAccent),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  items:
                      _tags.map((tag) {
                        return DropdownMenuItem<int>(
                          value: tag['id'],
                          child: Text(tag['tag_name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null && !_selectedTagIds.contains(value)) {
                      setState(() {
                        _selectedTagIds.add(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children:
                      _selectedTagIds.map((id) {
                        final tag = _tags.firstWhere((t) => t['id'] == id);
                        return Chip(
                          label: Text(tag['tag_name']),
                          onDeleted: () {
                            setState(() {
                              _selectedTagIds.remove(id);
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
