import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api_client.dart';
import '../../core/auth_utils.dart';
import '../../pages/list_all_project.dart';
import '../../pages/list_all_task.dart';
import '../../provider/connectivity_provider.dart';
import '../../provider/search_provider.dart';
import '../../provider/task_provider.dart';
import '../cart_loading.dart';
import '../tasks/task_card.dart';
import 'project_card.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  Future<List<dynamic>>? futureProjects;
  final ApiClient _apiClient = ApiClient();
  String? _token;
  bool _isLoading = true;
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadTokenAndFetchProjects();

    // Fetch tasks when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks(context);
    });
  }

  Future<void> _loadTokenAndFetchProjects() async {
    setState(() {
      _isLoading = true;
    });

    _token = await AuthUtils.getToken();
    if (_token != null) {
      final connectivityProvider = Provider.of<ConnectivityProvider>(
        context,
        listen: false,
      );

      if (connectivityProvider.isOnline) {
        await _fetchProjectsFromApi();
      } else {
        await _loadProjectsFromPrefs();
      }
    } else {
      setState(() {
        futureProjects = Future.value([]);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchProjectsFromApi() async {
    try {
      final projects = await _apiClient.projects(_token!);
      setState(() {
        futureProjects = Future.value(projects);
      });
      _prefs.setString('allProjects', jsonEncode(projects));
    } catch (e) {
      await _loadProjectsFromPrefs();
    }
  }

  Future<void> _loadProjectsFromPrefs() async {
    final String? storedProjects = _prefs.getString('allProjects');
    if (storedProjects != null && storedProjects.isNotEmpty) {
      setState(() {
        futureProjects = Future.value(jsonDecode(storedProjects));
      });
    } else {
      setState(() {
        futureProjects = Future.value([]);
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    await _loadTokenAndFetchProjects();
    await Provider.of<TaskProvider>(context, listen: false).fetchTasks(context);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivityProvider = Provider.of<ConnectivityProvider>(context);

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!connectivityProvider.isOnline)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 16,
                ),
                child: Row(
                  children: [
                    Icon(Icons.cloud_off, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _refreshData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Projects',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListAllProject(),
                        ),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              child:
                  _isLoading
                      ? ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return const CardLoading(
                            width: 300,
                            height: 200,
                            margin: EdgeInsets.only(right: 16),
                          );
                        },
                      )
                      : FutureBuilder<List<dynamic>>(
                        future: futureProjects,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: 4,
                              itemBuilder: (context, index) {
                                return const CardLoading(
                                  width: 300,
                                  height: 200,
                                  margin: EdgeInsets.only(right: 16),
                                );
                              },
                            );
                          } else if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          } else if (!snapshot.hasData ||
                              snapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('No projects found.'),
                            );
                          } else {
                            final searchQuery =
                                Provider.of<SearchProvider>(
                                  context,
                                ).query.toLowerCase();
                            final filteredProjects =
                                searchQuery.isEmpty
                                    ? snapshot.data!
                                    : snapshot.data!.where((project) {
                                      final projectName =
                                          project['name'].toLowerCase();
                                      final projectDescription =
                                          project['description'].toLowerCase();
                                      final projectTags =
                                          (project['tag'] as List<dynamic>)
                                              .map(
                                                (tag) =>
                                                    tag
                                                        .toString()
                                                        .toLowerCase(),
                                              )
                                              .toList();

                                      return projectName.contains(
                                            searchQuery,
                                          ) ||
                                          projectDescription.contains(
                                            searchQuery,
                                          ) ||
                                          projectTags.any(
                                            (tag) => tag.contains(searchQuery),
                                          );
                                    }).toList();

                            return filteredProjects.isEmpty
                                ? const Center(
                                  child: Text('No matching projects.'),
                                )
                                : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredProjects.length,
                                  itemBuilder: (context, index) {
                                    final project = filteredProjects[index];

                                    return GestureDetector(
                                      onTap: () {
                                        // Handle project tap
                                      },
                                      child: Container(
                                        width: 300,
                                        margin: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: ProjectCard(
                                          title: project['name'],
                                          subtitle: project['description'],
                                          progress:
                                              (project['progress'] as num)
                                                  .toDouble(),
                                          deadline: project['deadline'],
                                          date: project['created_at'],
                                          members: project['team'].length,
                                          tasks: project['tasks'].length,
                                          team:
                                              project['team'].isNotEmpty
                                                  ? project['team']
                                                  : [],
                                          taskImages: project['tasks'],
                                          tags:
                                              project['tag'].isNotEmpty
                                                  ? project['tag']
                                                  : [],
                                        ),
                                      ),
                                    );
                                  },
                                );
                          }
                        },
                      ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Today Tasks',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListAllTask()),
                      );
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Color(0xFF6B4EFF),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      return const CardLoading(
                        width: double.infinity,
                        height: 100,
                        margin: EdgeInsets.only(bottom: 16),
                      );
                    },
                  );
                }

                if (taskProvider.tasks.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No tasks available'),
                    ),
                  );
                }

                final taskData =
                    taskProvider.tasks.first['data'] as List<dynamic>;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: taskData.length > 4 ? 4 : taskData.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final task = taskData[index];
                    final title = task['title'] as String;
                    final projectName = task['project_name'] as String;
                    final dueDate = task['due_date'] as String;
                    final team = task['team'] as List<dynamic>;
                    final status = task['status'] as String;
                    final tags = task['tags'] as List<dynamic>;
                    final progress = 0.1 + (index * 0.3) % 0.9;

                    return TaskCard(
                      title: title,
                      projectName: projectName,
                      dueDate: dueDate,
                      progress: progress,
                      team: team,
                      status: status,
                      tags: tags,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
