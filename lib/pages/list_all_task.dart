import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_client.dart';
import '../core/connectivity_manager.dart';
import '../core/offline_task_manager.dart';
import '../core/user_service.dart';
import '../provider/all_task_provider.dart';
import '../provider/connectivity_provider.dart';
import '../provider/theme_provider.dart';
import '../widget/tasks/task_card.dart';
import '../widget/tasks/task_form_modal.dart';
import 'home.dart'; // Import your ApiClient

class ListAllTask extends StatefulWidget {
  const ListAllTask({super.key});

  @override
  State<ListAllTask> createState() => _ListAllTaskState();
}

class _ListAllTaskState extends State<ListAllTask> {
  final TextEditingController _searchController = TextEditingController();
  late ConnectivityProvider connectivityProvider;
  List<dynamic> _filteredTasks = [];
  String _searchQuery = '';
  late ApiClient _apiClient;
  List<Map<String, dynamic>> userInfo = [];
  final RefreshController _refreshController = RefreshController();
  bool _isLoading = true;
  bool _isDisposed = false;
  final ConnectivityManager _connectivityManager = ConnectivityManager();

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    connectivityProvider = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    // Initialize connectivity and set up listener
    _initializeConnectivity().then((_) {
      if (!_isDisposed) {
        _loadTasks();
      }
    });

    /// Add a test notification after widget initialization for testing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure online status document exists for this user
      if (userInfo.isNotEmpty && userInfo[0]['id'] != null) {
        final String userId = userInfo[0]['id'].toString();
        UserService.ensureUserDocument(userId, online: true);
      }
    });
  }

  Future<void> _initializeConnectivity() async {
    await _connectivityManager.initialize();
    _connectivityManager.addListener(() {
      if (!_isDisposed) {
        _handleConnectivityChange();
      }
    });
  }

  void _handleConnectivityChange() {
    if (!_isDisposed) {
      setState(() {
        // This will trigger a rebuild with the new connectivity state
      });

      if (_connectivityManager.isOnline) {
        // When coming back online, refresh tasks
        _loadTasks();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _searchController.dispose();
    _refreshController.dispose();
    _connectivityManager.removeListener(_handleConnectivityChange);
    super.dispose();
  }

  Future<void> _onRefresh() async {
    if (_isDisposed) return;

    final taskProvider = Provider.of<AllTaskProvider>(context, listen: false);
    await taskProvider.refreshTasks();
    if (!_isDisposed) {
      _refreshController.refreshCompleted();
      _loadTasks();
    }
  }

  // Function to fetch tasks from the API
  Future<void> _loadTasks() async {
    if (_isDisposed || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (!mounted) return;
      final taskProvider = Provider.of<AllTaskProvider>(context, listen: false);
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );

      if (connectivityProvider.isOnline) {
        await taskProvider.fetchAllTasks();
        if (!_isDisposed &&
            mounted &&
            taskProvider.tasks.isNotEmpty &&
            taskProvider.tasks[0]['data'] != null) {
          setState(() {
            _filteredTasks = taskProvider.tasks[0]['data'];
          });
        }
      } else {
        // Load offline tasks
        final offlineTasks = await OfflineTaskManager().getOfflineTasks();
        if (!_isDisposed && mounted) {
          setState(() {
            _filteredTasks = offlineTasks;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading tasks: $e');
      }
      // Try to load cached tasks if available
      final cachedTasks = await OfflineTaskManager().getOfflineTasks();
      if (!_isDisposed && mounted && cachedTasks.isNotEmpty) {
        setState(() {
          _filteredTasks = cachedTasks;
        });
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _performTaskDeletion(dynamic taskId) async {
    if (_isDisposed || taskId == null) return;

    try {
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Center(child: Text('Deleting task...')),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 2),
          ),
        );
      }

      final ApiClient apiClient = ApiClient();
      await apiClient.deleteTask(taskId);

      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        await _loadTasks();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task: $e');
      }
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deletion failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filter tasks based on search query
  void _filterTasks(String query) {
    if (_isDisposed) return;

    setState(() {
      _searchQuery = query.toLowerCase();
      if (_searchQuery.isEmpty) {
        _filteredTasks = _filteredTasks;
      } else {
        _filteredTasks =
            _filteredTasks.where((task) {
              final title = task['title']?.toString().toLowerCase() ?? '';
              final projectName =
                  task['project_name']?.toString().toLowerCase() ?? '';
              return title.contains(_searchQuery) ||
                  projectName.contains(_searchQuery);
            }).toList();
      }
    });
  }

  // Create or edit task
  Future<void> _showTaskForm({Map<dynamic, dynamic>? task}) async {
    if (_isDisposed) return;

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? userData = prefs.getString('userData');
      String? token;

      if (userData != null && userData.isNotEmpty) {
        final List<dynamic> userDataMap = jsonDecode(userData);
        if (userDataMap.isNotEmpty && userDataMap[0]['token'] != null) {
          token = userDataMap[0]['token'].toString();
        }
      }

      if (!mounted) return;

      final bool isEditing = task != null;
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder:
            (context) => TaskFormModal(
              task: task,
              apiClient: _apiClient,
              token: token,
              onTaskSaved: (bool success) async {
                if (success && !_isDisposed && mounted) {
                  await _loadTasks();
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
                }
              },
            ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing task form: $e');
      }
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showTaskDelete({Map<dynamic, dynamic>? task}) async {
    if (_isDisposed || task == null || task['id'] == null) return;

    try {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 10),
                Text('Warning'),
              ],
            ),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _performTaskDeletion(task['id']);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error showing delete dialog: $e');
      }
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    final isOnline = connectivityProvider.isOnline;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Home()),
              ),
        ),
        title: const Text('All Tasks'),
        backgroundColor: themeProvider.getAdaptiveCardColor(context),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search tasks...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: themeProvider.getAdaptiveCardColor(context),
              ),
              onChanged: _filterTasks,
            ),
          ),
          if (!isOnline)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Icon(Icons.wifi_off, color: Colors.orange.shade800),
                  const SizedBox(width: 8),

                  const Spacer(),
                  TextButton.icon(
                    onPressed: _onRefresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredTasks.isEmpty
                    ? const Center(
                      child: Text(
                        'No tasks found',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                    : ReorderableListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _filteredTasks.removeAt(oldIndex);
                          _filteredTasks.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return TaskCard(
                          key: ValueKey(task['id'] ?? index),
                          task: task,
                          title: task['title'] ?? '',
                          projectName: task['project_name'] ?? '',
                          dueDate: task['due_date'] ?? '',
                          progress: 0.0,
                          team: task['team'] ?? [],
                          status: task['status'] ?? '',
                          tags: task['tags'] ?? [],
                          onEdit: () => _showTaskForm(task: task),
                          onDelete: () => _showTaskDelete(task: task),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTaskForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
