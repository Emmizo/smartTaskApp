import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:smart_task_app/core/api_client.dart';
import 'package:smart_task_app/core/auth_utils.dart';

import 'package:smart_task_app/pages/list_all_project.dart';
import 'package:smart_task_app/pages/list_all_task.dart';
import 'package:smart_task_app/provider/search_provider.dart';
import 'package:smart_task_app/provider/task_provider.dart';
import 'package:smart_task_app/widget/projects/project_card.dart';

class ProjectList extends StatefulWidget {
  const ProjectList({Key? key}) : super(key: key);

  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  Future<List<dynamic>>? futureProjects;
  final ApiClient _apiClient = ApiClient();
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchProjects();

    // Fetch tasks when widget initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).fetchTasks();
    });
  }

  Future<void> _loadTokenAndFetchProjects() async {
    setState(() {
      _isLoading = true;
    });

    _token = await AuthUtils.getToken();
    if (_token != null) {
      final projectsFuture = _apiClient.projects(_token!);
      setState(() {
        futureProjects = projectsFuture;
      });
    } else {
      setState(() {
        futureProjects = Future.value([]);
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Projects Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      MaterialPageRoute(builder: (context) => ListAllProject()),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 4, // Show 4 loading cards
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
                              snapshot.data!
                                  .where((project) {
                                    final projectName =
                                        project['name'].toLowerCase();
                                    final projectDescription =
                                        project['description'].toLowerCase();
                                    final projectTags =
                                        (project['tag'] as List<dynamic>)
                                            .map(
                                              (tag) =>
                                                  tag.toString().toLowerCase(),
                                            )
                                            .toList();

                                    return projectName.contains(searchQuery) ||
                                        projectDescription.contains(
                                          searchQuery,
                                        ) ||
                                        projectTags.any(
                                          (tag) => tag.contains(searchQuery),
                                        );
                                  })
                                  .take(4)
                                  .toList();
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
                                      /* Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) => CreateTaskFormModal(
                                                apiClient: apiClient,
                                                projectId: projectId,
                                                token: _token ?? '',
                                              ),
                                        ),
                                      ); */
                                    },
                                    child: Container(
                                      width: 300,
                                      margin: const EdgeInsets.only(right: 16),
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
                                                ? project['team'][0]
                                                : [],
                                        taskImages: project['tasks'],
                                        tags:
                                            project['tag'].isNotEmpty
                                                ? project['tag'][0]
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

          // Tasks Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
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
                  itemCount: 4, // Show 4 loading cards
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

              // Extract the 'data' array from the response
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

                  // Calculate progress
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
          // Add some bottom padding to ensure nothing gets cut off
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String projectName;
  final String dueDate;
  final double progress;
  final String status;
  final List<dynamic> team;
  final List<dynamic> tags;

  const TaskCard({
    super.key,
    required this.title,
    required this.projectName,
    required this.dueDate,
    required this.progress,
    required this.status,
    required this.team,
    required this.tags,
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
      case 'normal':
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
                          child: Text(
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
                          child: Text(
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
                    Text(
                      'Project: $projectName • Due: $formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
            ],
          ),
        ],
      ),
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
          child: Text(
            tagName,
            style: TextStyle(fontSize: 10, color: Colors.grey[700]),
          ),
        ),
      );
    }

    return tagWidgets;
  }
}
