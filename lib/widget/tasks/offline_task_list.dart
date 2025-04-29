import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/offline_task_manager.dart';
import '../../provider/connectivity_provider.dart';
import '../../provider/theme_provider.dart';

class OfflineTaskList extends StatefulWidget {
  const OfflineTaskList({super.key});

  @override
  State<OfflineTaskList> createState() => _OfflineTaskListState();
}

class _OfflineTaskListState extends State<OfflineTaskList> {
  List<Map<String, dynamic>> _offlineTasks = [];
  List<Map<String, dynamic>> _offlineTaskUpdates = [];
  bool _isLoading = true;
  final OfflineTaskManager _offlineManager = OfflineTaskManager();

  @override
  void initState() {
    super.initState();
    _loadOfflineTasks();
  }

  Future<void> _loadOfflineTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final offlineTasks = await _offlineManager.getOfflineTasks();
      final offlineUpdates = await _offlineManager.getOfflineTaskUpdates();

      setState(() {
        _offlineTasks = offlineTasks;
        _offlineTaskUpdates = offlineUpdates;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading offline tasks: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);
    final isOnline = connectivityProvider.isOnline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.getAdaptiveCardColor(context),
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
          // Header with offline indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Offline Tasks',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              if (!isOnline)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi_off, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          // No offline tasks message
          else if (_offlineTasks.isEmpty && _offlineTaskUpdates.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No offline tasks. All tasks are synced.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          // Offline tasks list
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // New tasks waiting to be created
                if (_offlineTasks.isNotEmpty) ...[
                  const Text(
                    'New Tasks',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _offlineTasks.length,
                    itemBuilder: (context, index) {
                      final task = _offlineTasks[index];
                      return _buildOfflineTaskCard(
                        task,
                        'New Task',
                        Colors.blue,
                        isOnline,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Task updates waiting to be synced
                if (_offlineTaskUpdates.isNotEmpty) ...[
                  const Text(
                    'Task Updates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _offlineTaskUpdates.length,
                    itemBuilder: (context, index) {
                      final update = _offlineTaskUpdates[index];
                      return _buildOfflineTaskCard(
                        update,
                        'Update',
                        Colors.orange,
                        isOnline,
                      );
                    },
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOfflineTaskCard(
    Map<String, dynamic> task,
    String type,
    Color color,
    bool isOnline,
  ) {
    final title = task['title'] ?? 'Untitled Task';
    final projectName = task['project_name'] ?? 'Unknown Project';
    final dueDate = task['due_date'] ?? DateTime.now().toIso8601String();
    final status =
        task['status_id'] == 1
            ? 'Low'
            : task['status_id'] == 2
            ? 'Medium'
            : 'High';

    // Create a team list for the task card
    final team =
        task['user_id'] != null && task['user_id'] is List
            ? task['user_id'] as List<dynamic>
            : [];

    // Create a tags list for the task card
    final tags =
        task['tag_id'] != null
            ? task['tag_id']
                .toString()
                .split(',')
                .map((id) => {'id': int.parse(id)})
                .toList()
            : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              if (!isOnline)
                const Icon(Icons.wifi_off, size: 16, color: Colors.amber),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Project: $projectName • Due: ${_formatDate(dueDate)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(status),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getStatusColor(status),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
