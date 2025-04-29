import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_client.dart';
import '../../core/global.dart' as global;
import '../../core/notification_service.dart';
import '../../pages/home.dart';
import '../../provider/get_tag_provider.dart';
import '../../provider/get_user_provider.dart';
import '../../provider/theme_provider.dart';

class ProjectModalService {
  static void showCreateProjectModal() {
    final context = global.navigatorKey.currentContext!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateProjectModal(),
    );
  }
}

class CreateProjectModal extends StatefulWidget {
  const CreateProjectModal({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateProjectModalState createState() => _CreateProjectModalState();
}

class _CreateProjectModalState extends State<CreateProjectModal> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDeadline;
  final List<int> _selectedUserIds = [];
  final List<int> _selectedTagIds = [];
  List<dynamic> _users = [];
  List<dynamic> _tags = [];
  bool _formSubmitted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Delay the fetchUsers call until after the build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUsers();
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
        _users = getUserProvider.users.first['data'] as List<dynamic>;
      });
    }
  }

  Future<void> fetchTags() async {
    final getTagProvider = Provider.of<GetTagProvider>(context, listen: false);
    await getTagProvider.fetchTags();

    // Update the UI with fetched users
    if (getTagProvider.tags.isNotEmpty) {
      setState(() {
        _tags = getTagProvider.tags.first['data'] as List<dynamic>;
      });
    }
  }

  Future<void> createProject() async {
    setState(() {
      _formSubmitted = true;
    });

    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Project name is required'),
          backgroundColor: Colors.red.shade300,
        ),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Project description is required'),
          backgroundColor: Colors.red.shade300,
        ),
      );
      return;
    }

    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a deadline'),
          backgroundColor: Colors.red.shade300,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Center(child: Text('Processing Sign Up...')),
        backgroundColor: Colors.blue.shade300,
      ),
    );

    final SharedPreferences prefs = await _prefs;
    final String? userData = prefs.getString('userData');

    if (userData != null && userData.isNotEmpty) {
      final List<dynamic> userDataMap = jsonDecode(userData);
      final String? token = userDataMap[0]['token']?.toString();

      try {
        final ApiClient apiClient = ApiClient();
        final response = await apiClient.CreateProject(
          _nameController.text,
          _descriptionController.text,
          _selectedDeadline ?? DateTime.now(),
          _selectedUserIds,
          _selectedTagIds,
          token ?? '',
        );
        // Extract project ID from response
        final projectId = response['project_id']?.toString() ?? '';

        await Future.delayed(const Duration(seconds: 2));
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Trigger notification for project creation
        await NotificationService().showProjectCreatedNotification(
          _nameController.text,
          projectId,
        );
        final List<String> userIdStrings =
            _selectedUserIds.map((id) => id.toString()).toList();

        // Send notifications to all assigned users
        await NotificationService().sendNotificationToUsers(
          userIdStrings,
          'New Project Assignment',
          'You have been assigned to project "${_nameController.text}"',
          projectId: projectId,
          data: {
            'type': 'project_assignment',
            'projectId': projectId,
            'projectName': _nameController.text,
          },
        );

        // Show professional dialog instead of a snackbar
        showDialog(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 10),
                  Text('Success'),
                ],
              ),
              content: const Text('Project created successfully!'),
              actions: [
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Home()),
                    );
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Creating failed: ${e.toString()}'),
            backgroundColor: Colors.red.shade300,
          ),
        );
      }
    }
  }

  void _pickDeadline() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDeadline = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: themeProvider.getAdaptiveCardColor(context),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24.0),
            topRight: Radius.circular(24.0),
          ),
          boxShadow: [
            const BoxShadow(
              color: Colors.black,
              blurRadius: 10.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Center(
                child: Text(
                  'Create Project',
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24.0),

              // Project Name
              const Text(
                'Project Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter project name',
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
                  errorText:
                      _formSubmitted && _nameController.text.isEmpty
                          ? 'Project name is required'
                          : null,
                ),
              ),
              const SizedBox(height: 20.0),

              // Project Description
              const Text(
                'Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8.0),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter project description',
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
                  errorText:
                      _formSubmitted && _descriptionController.text.isEmpty
                          ? 'Project description is required'
                          : null,
                ),
              ),
              const SizedBox(height: 20.0),

              // Deadline Picker
              const Text(
                'Deadline',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8.0),
              InkWell(
                onTap: _pickDeadline,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.getAdaptiveCardColor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color:
                          _formSubmitted && _selectedDeadline == null
                              ? Colors.red
                              : Colors.grey,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDeadline == null
                            ? 'Select Deadline'
                            : DateFormat(
                              'yyyy-MM-dd',
                            ).format(_selectedDeadline!),
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _selectedDeadline == null
                                  ? Colors.grey
                                  : Colors.black87,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.blueAccent,
                      ),
                    ],
                  ),
                ),
              ),
              if (_formSubmitted && _selectedDeadline == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    'Please select a deadline',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20.0),

              // User selection
              const Text(
                'Assign Users',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8.0),
              DropdownButtonFormField<int>(
                decoration: InputDecoration(
                  hintText: 'Select users',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: themeProvider.getAdaptiveCardColor(context),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  filled: true,
                  fillColor: themeProvider.getAdaptiveCardColor(context),
                ),
                items:
                    _users.map((user) {
                      return DropdownMenuItem<int>(
                        value: user['id'],
                        child: Text(user['first_name'] ?? ''),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null && !_selectedUserIds.contains(value)) {
                    setState(() {
                      _selectedUserIds.add(value);
                    });
                  }
                },
              ),
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children:
                    _selectedUserIds.map((id) {
                      final user = _users.firstWhere((u) => u['id'] == id);
                      return Chip(
                        label: Text(user['first_name']),
                        onDeleted: () {
                          setState(() {
                            _selectedUserIds.remove(id);
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 20.0),

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
                    _tags.map((tag) {
                      return DropdownMenuItem<int>(
                        value: tag['id'],
                        child: Text(tag['name']),
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
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 8.0,
                children:
                    _selectedTagIds.map((id) {
                      final tag = _tags.firstWhere((t) => t['id'] == id);
                      return Chip(
                        label: Text(tag['name']),
                        onDeleted: () {
                          setState(() {
                            _selectedTagIds.remove(id);
                          });
                        },
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24.0),

              // Submit Button
              ElevatedButton(
                onPressed: () {
                  createProject();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 3, 63, 113),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16.0),
                ),
                child: const SizedBox(
                  width: double.infinity,
                  child: Center(
                    child: Text(
                      'Create Project',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
